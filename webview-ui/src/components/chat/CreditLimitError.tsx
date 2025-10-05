import { AskResponseRequest } from "@shared/proto/cline/task"
import { VSCodeButton } from "@vscode/webview-ui-toolkit/react"
import React from "react"
import { TaskServiceClient } from "@/services/grpc-client"

interface CreditLimitErrorProps {
	currentBalance: number
	totalSpent?: number
	totalPromotions?: number
	message: string
	buyCreditsUrl?: string
}

const CreditLimitError: React.FC<CreditLimitErrorProps> = ({
	message = "You have run out of credits.",
}) => {
	// Credits and billing have been disabled in Opencline
	return (
		<div className="p-2 border-none rounded-md mb-2 bg-[var(--vscode-textBlockQuote-background)]">
			<div className="mb-3 font-azeret-mono">
				<div className="text-error mb-2">Credit system has been disabled in Opencline</div>
				<div className="mb-3">
					<div className="text-foreground">
						The original error was: {message}
					</div>
					<div className="text-foreground mt-2">
						Please configure your own API keys in Settings to continue using Opencline.
					</div>
				</div>
			</div>

			<VSCodeButton
				appearance="secondary"
				className="w-full"
				onClick={async () => {
					try {
						await TaskServiceClient.askResponse(
							AskResponseRequest.create({
								responseType: "yesButtonClicked",
							}),
						)
					} catch (error) {
						console.error("Error invoking action:", error)
					}
				}}>
				<span className="codicon codicon-refresh mr-1.5" />
				Retry Request
			</VSCodeButton>
		</div>
	)
}

export default CreditLimitError
