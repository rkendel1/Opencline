import { expect } from "@playwright/test"
import { e2e } from "./utils/helpers"

// Test for setting up API keys
e2e("Views - can set up API keys and navigate to Settings from Chat", async ({ sidebar }) => {
	// Use the page object to interact with editor outside the sidebar
	// Verify initial state - authentication has been removed, so welcome view shows API options directly
	const providerSelectorInput = sidebar.getByTestId("provider-selector-input")

	// Verify provider selector is visible on welcome screen
	await expect(providerSelectorInput).toBeVisible()

	// Test switching to OpenRouter and completing setup
	await providerSelectorInput.click({ delay: 100 })
	await sidebar.getByTestId("provider-option-openrouter").click({ delay: 100 })

	const apiKeyInput = sidebar.getByRole("textbox", {
		name: "OpenRouter API Key",
	})
	await apiKeyInput.fill("test-api-key")
	await expect(apiKeyInput).toHaveValue("test-api-key")
	await apiKeyInput.click({ delay: 100 })
	const submitButton = sidebar.getByRole("button", { name: "Let's go!" })
	await expect(submitButton).toBeEnabled()
	await submitButton.click({ delay: 100 })

	// Verify start up page is no longer visible
	await expect(apiKeyInput).not.toBeVisible()
	await expect(providerSelectorInput).not.toBeVisible()

	// Verify you are now in the chat page after setup was completed
	const clineLogo = sidebar.getByRole("img").filter({ hasText: /^$/ }).locator("path")
	await expect(clineLogo).toBeVisible()
	const chatInputBox = sidebar.getByTestId("chat-input")
	await expect(chatInputBox).toBeVisible()

	// Verify the release banner is visible for new installs and can be closed.
	const releaseBanner = sidebar.getByRole("heading", {
		name: /^🎉 New in v\d/,
	})
	await expect(releaseBanner).toBeVisible()
	await sidebar.getByTestId("close-button").locator("span").first().click()
	await expect(releaseBanner).not.toBeVisible()
})
