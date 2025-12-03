
/**
 * Fade the player's screen to black.
 * If the duration is negative, the fade lasts indefinitely until it is cleared.
 */
UFUNCTION(Category = "Fade", DisplayName = "Fade Out Player")
mixin void FadeOut(AHazePlayerCharacter PlayerCharacter, FInstigator Instigator, float FadeDuration = -1.0, float FadeOutTime = 0.5, float FadeInTime = 0.5)
{
    auto Manager = UFadeManagerComponent::GetOrCreate(PlayerCharacter);
    Manager.AddFade(Instigator, FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Gameplay);
}

/**
 * Fade the player's screen to a specific color.
 * If the duration is negative, the fade lasts indefinitely until it is cleared.
 */
UFUNCTION(Category = "Fade", DisplayName = "Fade Player to Color")
mixin void FadeToColor(AHazePlayerCharacter PlayerCharacter, FInstigator Instigator, FLinearColor FadeColor, float FadeDuration = -1.0, float FadeOutTime = 0.5, float FadeInTime = 0.5)
{
    auto Manager = UFadeManagerComponent::GetOrCreate(PlayerCharacter);
    Manager.AddFadeToColor(Instigator, FadeColor, FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Gameplay);
}

/**
 * Clear a previously created fade on the player, overriding the original fade in time.
 */
UFUNCTION(Category = "Fade", DisplayName = "Clear Player Fades")
mixin void ClearFade(AHazePlayerCharacter PlayerCharacter, FInstigator Instigator, float FadeInTime = 0.5)
{
    auto Manager = UFadeManagerComponent::GetOrCreate(PlayerCharacter);
    Manager.ClearFade(Instigator, FadeInTime);
}

/**
 * Fade both players' screens to black, overriding any individual fades they already have.
 * If the duration is negative, the fade lasts indefinitely until it is cleared.
 */
UFUNCTION(Category = "Fade")
void FadeOutFullscreen(FInstigator Instigator, float FadeDuration = -1.0, float FadeOutTime = 0.5, float FadeInTime = 0.5)
{
    for (auto Player : Game::GetPlayers())
    {
        auto Manager = UFadeManagerComponent::GetOrCreate(Player);
        Manager.AddFade(Instigator, FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Fullscreen);
    }
}

/**
 * Fade the whole screen to a specific color.
 * If the duration is negative, the fade lasts indefinitely until it is cleared.
 */
UFUNCTION(Category = "Fade")
void FadeFullscreenToColor(FInstigator Instigator, FLinearColor FadeColor, float FadeDuration = -1.0, float FadeOutTime = 0.5, float FadeInTime = 0.5)
{
    for (auto Player : Game::GetPlayers())
    {
        auto Manager = UFadeManagerComponent::GetOrCreate(Player);
        Manager.AddFadeToColor(Instigator, FadeColor, FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Fullscreen);
    }
}

/**
 * Clear a fullscreen fade that was added previously.
 */
UFUNCTION(Category = "Fade")
void ClearFullscreenFade(FInstigator Instigator, float FadeInTime = 0.5)
{
    for (auto Player : Game::GetPlayers())
    {
        auto Manager = UFadeManagerComponent::GetOrCreate(Player);
        Manager.ClearFade(Instigator, FadeInTime);
    }
}

/**
 * Make sure the next loading screen is faded out for at least this duration of time.
 */
UFUNCTION(Category = "Fade")
void SetMinimumDurationForNextLoadingScreen(float Duration)
{
	auto Singleton = Game::GetSingleton(UFadeSingleton);
	Singleton.NextLoadingScreenMinimumDuration = Duration;
}