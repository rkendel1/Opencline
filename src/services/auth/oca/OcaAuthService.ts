import { type EmptyRequest, String as ProtoString } from "@shared/proto/cline/common"
import { OcaAuthState, OcaUserInfo } from "@shared/proto/cline/oca_account"
import type { Controller } from "@/core/controller"
import { getRequestRegistry, type StreamingResponseHandler } from "@/core/controller/grpc-handler"
import { AuthHandler } from "@/hosts/external/AuthHandler"
import { openExternal } from "@/utils/env"
import { OcaAuthProvider } from "./providers/OcaAuthProvider"
import type { OcaConfig } from "./utils/types"
import { getOcaConfig } from "./utils/utils"
// import { AuthHandler } from "@/hosts/external/AuthHandler"

export class OcaAuthService {
	protected static instance: OcaAuthService | null = null
	protected readonly _config: OcaConfig
	protected _authenticated: boolean = false
	protected _ocaAuthState: OcaAuthState | null = null
	protected _provider: OcaAuthProvider | null = null
	protected _controller: Controller | null = null
	protected _refreshInFlight: Promise<void> | null = null
	protected _interactiveLoginPending: boolean = false
	protected _activeAuthStatusUpdateSubscriptions = new Set<{
		controller: Controller
		responseStream: StreamingResponseHandler<OcaAuthState>
	}>()

	protected constructor() {
		this._config = getOcaConfig()
		this._provider = new OcaAuthProvider(this._config)
	}

	private requireController(): Controller {
		if (this._controller) {
			return this._controller
		}
		throw new Error("Controller has not been initialized")
	}

	private requireProvider(): OcaAuthProvider {
		if (!this._provider) {
			throw new Error("Auth provider is not set")
		}
		return this._provider
	}

	/**
	 * Initializes the singleton with a Controller.
	 * Safe to call multiple times; updates controller on existing instance.
	 */
	public static initialize(controller: Controller): OcaAuthService {
		if (!OcaAuthService.instance) {
			OcaAuthService.instance = new OcaAuthService()
		}
		OcaAuthService.instance._controller = controller
		return OcaAuthService.instance
	}

	/**
	 * Gets the singleton instance of OcaAuthService.
	 * Throws if not initialized. Call initialize(controller) first.
	 */
	public static getInstance(): OcaAuthService {
		if (!OcaAuthService.instance || !OcaAuthService.instance._controller) {
			throw new Error("OcaAuthService not initialized. Call OcaAuthService.initialize(controller) first.")
		}
		return OcaAuthService.instance
	}

	/**
	 * Returns a current OCA authentication state.
	 */
	getInfo(): OcaAuthState {
		let user: OcaUserInfo | undefined
		if (this._ocaAuthState && this._authenticated) {
			const userInfo = this._ocaAuthState.user
			user = OcaUserInfo.create({
				uid: userInfo?.uid,
				displayName: userInfo?.displayName,
				email: userInfo?.email,
			})
		}
		return OcaAuthState.create({ user })
	}

	public get isAuthenticated(): boolean {
		return this._authenticated
	}

	private async refreshAuthState(): Promise<void> {
		// Single-flight to avoid concurrent refresh storms
		if (this._refreshInFlight) {
			await this._refreshInFlight
			return
		}
		this._refreshInFlight = (async () => {
			try {
				await this.restoreRefreshTokenAndRetrieveAuthInfo()
			} finally {
				this._refreshInFlight = null
			}
		})()
		await this._refreshInFlight
	}

	async getAuthToken(): Promise<string | null> {
		// OCA Authentication disabled in Opencline - always return null
		return null
	}

	async createAuthRequest(): Promise<ProtoString> {
		// OCA Authentication disabled in Opencline
		return ProtoString.create({ value: "OCA Authentication has been disabled in Opencline" })
	}

	async handleDeauth(): Promise<void> {
		// OCA Authentication disabled - no-op
		this._ocaAuthState = null
		this._authenticated = false
	}

	private clearAuth(): void {
		const ctrl = this.requireController()
		this.requireProvider().clearAuth(ctrl)
	}

	async handleAuthCallback(code: string, state: string): Promise<void> {
		// OCA Authentication disabled - no-op
		console.log("OCA Authentication callback ignored - authentication disabled in Opencline")
	}

	async restoreRefreshTokenAndRetrieveAuthInfo(): Promise<void> {
		// OCA Authentication disabled - no-op
		this._authenticated = false
		this._ocaAuthState = null
	}

	private async kickstartInteractiveLoginAsFallback(_err?: unknown): Promise<void> {
		// OCA Authentication disabled - no-op
		console.log("Interactive login disabled in Opencline")
	}

	async subscribeToAuthStatusUpdate(
		_request: EmptyRequest,
		responseStream: StreamingResponseHandler<OcaAuthState>,
		requestId?: string,
	): Promise<void> {
		console.log("Subscribing to authStatusUpdate")
		const ctrl = this.requireController()
		if (!this._ocaAuthState) {
			this._ocaAuthState = await this.requireProvider().getExistingAuthState(ctrl)
			this._authenticated = !!this._ocaAuthState
		}
		const entry = { controller: ctrl, responseStream }
		this._activeAuthStatusUpdateSubscriptions.add(entry)
		const cleanup = () => {
			this._activeAuthStatusUpdateSubscriptions.delete(entry)
		}
		if (requestId) {
			getRequestRegistry().registerRequest(requestId, cleanup, { type: "authStatusUpdate_subscription" }, responseStream)
		}
		try {
			await this.sendAuthStatusUpdate()
		} catch (error) {
			console.error("Error sending initial auth status:", error)
			this._activeAuthStatusUpdateSubscriptions.delete(entry)
		}
	}

	async sendAuthStatusUpdate(): Promise<void> {
		if (this._activeAuthStatusUpdateSubscriptions.size === 0) {
			return
		}
		const postedControllers = new Set<Controller>()
		const promises = Array.from(this._activeAuthStatusUpdateSubscriptions).map(async (entry) => {
			const { controller: ctrl, responseStream } = entry
			try {
				const authInfo: OcaAuthState = this.getInfo()
				await responseStream(authInfo, false)
				if (ctrl && !postedControllers.has(ctrl)) {
					postedControllers.add(ctrl)
					await ctrl.postStateToWebview()
				}
			} catch (error) {
				console.error("Error sending authStatusUpdate event:", error)
				this._activeAuthStatusUpdateSubscriptions.delete(entry)
			}
		})
		await Promise.all(promises)
	}
}
