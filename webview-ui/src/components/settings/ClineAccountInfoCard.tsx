import { useClineAuth } from "@/context/ClineAuthContext"
import { useExtensionState } from "@/context/ExtensionStateContext"

export const ClineAccountInfoCard = () => {
	const { clineUser } = useClineAuth()
	const { apiConfiguration, navigateToAccount } = useExtensionState()

	const user = apiConfiguration?.clineAccountId ? clineUser : undefined

	const handleShowAccount = () => {
		navigateToAccount()
	}

	// Return null if no user - no sign-in button
	if (!user) {
		return null
	}

	return (
		<div className="max-w-[600px]">
			{/* Removed sign-in/sign-up functionality - account features disabled */}
		</div>
	)
}
