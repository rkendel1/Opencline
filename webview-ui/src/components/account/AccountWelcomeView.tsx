import ClineLogoWhite from "../../assets/ClineLogoWhite"

export const AccountWelcomeView = () => (
	<div className="flex flex-col items-center pr-3">
		<ClineLogoWhite className="size-16 mb-4" />

		<p className="text-center">
			Account features have been disabled. Opencline is now completely free and open source without authentication requirements.
		</p>
		
		<p className="text-[var(--vscode-descriptionForeground)] text-xs text-center m-0">
			Configure your API keys in Settings to get started.
		</p>
	</div>
)
