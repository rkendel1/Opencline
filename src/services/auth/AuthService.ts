import { AuthState, UserInfo } from "@shared/proto/cline/account"
import { type EmptyRequest, String } from "@shared/proto/cline/common"
import { clineEnvConfig } from "@/config"
import { Controller } from "@/core/controller"
import { getRequestRegistry, type StreamingResponseHandler } from "@/core/controller/grpc-handler"
import { HostProvider } from "@/hosts/host-provider"
import { telemetryService } from "@/services/telemetry"
import { openExternal } from "@/utils/env"
import { featureFlagsService } from "../feature-flags"
import { ClineAuthProvider } from "./providers/ClineAuthProvider"
import { FirebaseAuthProvider } from "./providers/FirebaseAuthProvider"
import { IAuthProvider } from "./providers/IAuthProvider"

export type ServiceConfig = {
	URI?: string
	[key: string]: any
}

export interface ClineAuthInfo {
	/**
	 * accessToken
	 */
	idToken: string
	/**
	 * Short-lived refresh token
	 */
	refreshToken?: string
	/**
	 * Access token expiration time
	 * When expired, the access token needs to be refreshed using the refresh token.
	 */
	expiresAt?: number
	userInfo: ClineAccountUserInfo
}

export interface ClineAccountUserInfo {
	createdAt: string
	displayName: string
	email: string
	id: string
	organizations: ClineAccountOrganization[]
	/**
	 * Cline app base URL, used for webview UI and other client-side operations
	 */
	appBaseUrl?: string
	/**
	 * WorkOS IDP ID if user logged in via SSO
	 */
	subject?: string
}

export interface ClineAccountOrganization {
	active: boolean
	memberId: string
	name: string
	organizationId: string
	roles: string[]
}

export class AuthService {
	protected static instance: AuthService | null = null
	protected _authenticated: boolean = false
	protected _clineAuthInfo: ClineAuthInfo | null = null
	protected _provider: IAuthProvider | null = null
	protected _activeAuthStatusUpdateHandlers = new Set<StreamingResponseHandler<AuthState>>()
	protected _handlerToController = new Map<StreamingResponseHandler<AuthState>, Controller>()
	protected _controller: Controller

	/**
	 * Creates an instance of AuthService.
	 * @param controller - Optional reference to the Controller instance.
	 */
	protected constructor(controller: Controller) {
		// Default to firebase for now
		const providerName = featureFlagsService.getWorkOsAuthEnabled() ? "cline" : "firebase"
		this._setProvider(providerName)
		this._controller = controller
	}

	/**
	 * Gets the singleton instance of AuthService.
	 * @param controller - Optional reference to the Controller instance.
	 * @returns The singleton instance of AuthService.
	 */
	public static getInstance(controller?: Controller): AuthService {
		if (!AuthService.instance) {
			if (!controller) {
				console.warn("Extension context was not provided to AuthService.getInstance, using default context")
				controller = {} as Controller
			}
			if (process.env.E2E_TEST) {
				// Use require instead of import to avoid circular dependency issues
				// eslint-disable-next-line @typescript-eslint/no-var-requires
				const { AuthServiceMock } = require("./AuthServiceMock")
				AuthService.instance = AuthServiceMock.getInstance(controller)
			} else {
				AuthService.instance = new AuthService(controller)
			}
		}
		if (controller !== undefined && AuthService.instance) {
			AuthService.instance.controller = controller
		}
		return AuthService.instance!
	}

	set controller(controller: Controller) {
		this._controller = controller
	}

	get authProvider(): IAuthProvider | null {
		return this._provider
	}

	set authProvider(providerName: string) {
		this._setProvider(providerName)
	}

	/**
	 * Returns the current authentication token with the appropriate prefix.
	 * Refreshing it if necessary.
	 * 
	 * NOTE: Authentication has been disabled in Opencline - always returns null
	 */
	async getAuthToken(): Promise<string | null> {
		// Authentication disabled - always return null
		return null
	}

	protected _setProvider(providerName: string): void {
		// Only ClineAuthProvider is supported going forward
		// Keeping the providerName param for forward compatibility/telemetrye
		switch (providerName) {
			case "cline":
				this._provider = new ClineAuthProvider(clineEnvConfig)
				break
			case "firebase":
			default:
				this._provider = new FirebaseAuthProvider(clineEnvConfig)
				break
		}
	}

	getInfo(): AuthState {
		// TODO: this logic should be cleaner, but this will determine the authentication state for the webview -- if a user object is returned then the webview assumes authenticated, otherwise it assumes logged out (we previously returned a UserInfo object with empty fields, and this represented a broken logged in state)
		let user: any = null
		if (this._clineAuthInfo && this._authenticated) {
			const userInfo = this._clineAuthInfo.userInfo
			this._clineAuthInfo.userInfo.appBaseUrl = clineEnvConfig?.appBaseUrl

			user = UserInfo.create({
				// TODO: create proto for new user info type
				uid: userInfo?.id,
				displayName: userInfo?.displayName,
				email: userInfo?.email,
				photoUrl: undefined,
				appBaseUrl: userInfo?.appBaseUrl,
			})
		}

		return AuthState.create({
			user,
		})
	}

	async createAuthRequest(): Promise<String> {
		// Authentication disabled in Opencline
		return String.create({ value: "Authentication has been disabled in Opencline" })
	}

	async handleDeauth(): Promise<void> {
		// Authentication disabled - no-op
		this._clineAuthInfo = null
		this._authenticated = false
	}

	async handleAuthCallback(authorizationCode: string, provider: string): Promise<void> {
		// Authentication disabled - no-op
		console.log("Authentication callback ignored - authentication disabled in Opencline")
	}

	/**
	 * Clear the authentication token from the extension's storage.
	 * This is typically called when the user logs out.
	 */
	async clearAuthToken(): Promise<void> {
		this._controller.stateManager.setSecret("clineAccountId", undefined)
	}

	/**
	 * Restores the authentication data from the extension's storage.
	 * This is typically called when the extension is activated.
	 * 
	 * NOTE: Authentication has been disabled in Opencline - no-op
	 */
	async restoreRefreshTokenAndRetrieveAuthInfo(): Promise<void> {
		// Authentication disabled - no-op
		this._authenticated = false
		this._clineAuthInfo = null
	}

	/**
	 * Subscribe to authStatusUpdate events
	 * @param controller The controller instance
	 * @param request The empty request
	 * @param responseStream The streaming response handler
	 * @param requestId The ID of the request (passed by the gRPC handler)
	 */
	async subscribeToAuthStatusUpdate(
		controller: Controller,
		_request: EmptyRequest,
		responseStream: StreamingResponseHandler<AuthState>,
		requestId?: string,
	): Promise<void> {
		console.log("Subscribing to authStatusUpdate")

		// Add this subscription to the active subscriptions
		this._activeAuthStatusUpdateHandlers.add(responseStream)
		this._handlerToController.set(responseStream, controller)
		// Register cleanup when the connection is closed
		const cleanup = () => {
			this._activeAuthStatusUpdateHandlers.delete(responseStream)
			this._handlerToController.delete(responseStream)
		}
		// Register the cleanup function with the request registry if we have a requestId
		if (requestId) {
			getRequestRegistry().registerRequest(requestId, cleanup, { type: "authStatusUpdate_subscription" }, responseStream)
		}

		// Send the current authentication status immediately
		try {
			await this.sendAuthStatusUpdate()
		} catch (error) {
			console.error("Error sending initial auth status:", error)
			// Remove the subscription if there was an error
			this._activeAuthStatusUpdateHandlers.delete(responseStream)
			this._handlerToController.delete(responseStream)
		}
	}

	/**
	 * Send an authStatusUpdate event to all active subscribers
	 */
	async sendAuthStatusUpdate(): Promise<void> {
		// Compute once per broadcast
		const authInfo: AuthState = this.getInfo()
		const uniqueControllers = new Set<Controller>()

		// Send the event to all active subscribers
		const streamSends = Array.from(this._activeAuthStatusUpdateHandlers).map(async (responseStream) => {
			const controller = this._handlerToController.get(responseStream)
			if (controller) {
				uniqueControllers.add(controller)
			}
			try {
				await responseStream(
					authInfo,
					false, // Not the last message
				)
			} catch (error) {
				console.error("Error sending authStatusUpdate event:", error)
				// Remove the subscription if there was an error
				this._activeAuthStatusUpdateHandlers.delete(responseStream)
				this._handlerToController.delete(responseStream)
			}
		})

		await Promise.all(streamSends)

		// Identify the user in telemetry if available
		if (this._clineAuthInfo?.userInfo?.id) {
			telemetryService.identifyAccount(this._clineAuthInfo.userInfo)
			// Reset feature flags to ensure they are fetched for the new/logged in user
			featureFlagsService.reset()
		}
		// Poll feature flags to ensure they are up to date for all users
		await featureFlagsService.poll()

		// Update state in webviews once per unique controller
		await Promise.all(Array.from(uniqueControllers).map((c) => c.postStateToWebview()))
	}
}
