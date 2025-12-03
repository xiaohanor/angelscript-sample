struct FCurrentFade
{
    float Duration = 0.0;
    float Time = 0.0;
    float FadeInTime = 0.0;
    float FadeOutTime = 0.0;
	FInstigator Instigator;
	FLinearColor FadeColor;
    EFadePriority Priority = EFadePriority::MAX;
};

const int EXTRA_LOADING_SCREEN_FADE_FRAMES = 3;
const float LOADING_SCREEN_FADE_IN_LENGTH = 0.5;

const FConsoleVariable CVar_HazeFadeOutOnLoadingScreen("Haze.FadeOutOnLoadingScreen", 1);

UCLASS(NotPlaceable, NotBlueprintable)
class UFadeManagerComponent : UHazeFadeManagerComponent
{
	default PrimaryComponentTick.bTickEvenWhenPaused = true;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostPhysics;

    TArray<FCurrentFade> Fades;
    float CurrentFadeAlpha = 0.0;
	FLinearColor CurrentFadeColor = FLinearColor::Transparent;

	TOptional<FLinearColor> LoadingScreenFadeColor;

	int LoadingScreenRemainingFrames = 0;
	bool bIsFadingFromLoading = false;

	bool bIsInLoadingScreen = false;
	bool bWasFadedOutBeforeLoadingScreen = false;

	AHazePlayerCharacter OwningPlayer = nullptr;
	AHazeAdditionalCameraUser OwningMenuCameraUser = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		OwningMenuCameraUser = Cast<AHazeAdditionalCameraUser>(Owner);

#if !EDITOR
		// In cooked we are _always_ coming from a loading screen after the players are created
		LoadingScreenRemainingFrames = EXTRA_LOADING_SCREEN_FADE_FRAMES;
		bIsFadingFromLoading = true;
#endif
	}

	UFUNCTION(BlueprintOverride)
    void ClearFade(FInstigator Instigator, float FadeInTime)
    {
        for (int i = 0, Count = Fades.Num(); i < Count; ++i)
        {
            // Ignore fades with a different instigator than we're clearing
            if (Fades[i].Instigator != Instigator)
                continue;

            // If our fade in time is 0, delete the fade instead, we don't need to do any blending
            if (FadeInTime <= 0.0)
            {
                Fades.RemoveAt(i);
                --i; --Count;
                continue;
            }

            // Move the fade so it is immediately at the beginning of its fade in
            Fades[i].Duration = 0.0;
            Fades[i].FadeInTime = FadeInTime;
            Fades[i].Time = 0.0;
        }

        UpdateFades(0.0);
    }

	UFUNCTION(BlueprintOverride)
    void AddFade(FInstigator Instigator, float Duration, float FadeOutTime, float FadeInTime, EFadePriority Priority = EFadePriority::Gameplay)
    {
		AddFadeToColor(Instigator, FLinearColor::Black, Duration, FadeOutTime, FadeInTime, Priority);
    }

	UFUNCTION(BlueprintOverride)
    void AddFadeToColor(FInstigator Instigator, FLinearColor Color, float Duration, float FadeOutTime, float FadeInTime, EFadePriority Priority = EFadePriority::Gameplay)
    {
        FCurrentFade Fade;
        Fade.Duration = Duration;
        Fade.FadeInTime = FadeInTime;
        Fade.FadeOutTime = FadeOutTime;
        Fade.Time = 0.0;
        Fade.Priority = Priority;
		Fade.FadeColor = Color;
		Fade.Instigator = Instigator;
        Fades.Add(Fade);

        UpdateFades(0.0);
    }

    void UpdateFades(float DeltaSeconds)
    {
        // Each fade does its own blending of the current fade amount to their desired one,
        // then the highest fade amount among all of them is chosen.
		FLinearColor NextFadeColor = FLinearColor::Black;
        float NextFadeAlpha = 0.0;
        for (int i = 0, Count = Fades.Num(); i < Count; ++i)
        {
			auto& Fade = Fades[i];

            // Advance the fade's timer until it's reached its duration
            if (Fade.Duration >= 0.0)
            {
                Fade.Time += DeltaSeconds;
                if (Fade.Time >= Fade.Duration + Fade.FadeInTime + Fade.FadeOutTime)
                {
                    Fades.RemoveAt(i);
                    --i; --Count;
                    continue;
                }
            }

            // Determine whether we want to be faded or not right now, disregarding blend
            float TargetFadeAlpha = 1.0;
            float BlendTime = Fade.FadeOutTime;
            if (Fade.Duration >= 0.0)
            {
                // If we're fading back in
                if (Fade.Time > Fade.Duration + Fade.FadeOutTime)
                {
                    TargetFadeAlpha = 0.0;
                    BlendTime = Fade.FadeInTime;
                }
            }

            // Blend from our active fade alpha to our target using the appropriate blend speed
            float BlendedFadeAlpha = CurrentFadeAlpha;
            if (BlendTime == 0.0)
            {
                BlendedFadeAlpha = TargetFadeAlpha;
            }
            else if(DeltaSeconds != 0.0)
            {
                float MaxFadeDelta = DeltaSeconds / BlendTime;
                float FullDelta = (TargetFadeAlpha - CurrentFadeAlpha);
                BlendedFadeAlpha = CurrentFadeAlpha + Math::Clamp(FullDelta, -MaxFadeDelta, MaxFadeDelta);
            }

            // Choose the highest blended fade alpha out of all our fades
            if (BlendedFadeAlpha > NextFadeAlpha)
			{
                NextFadeAlpha = BlendedFadeAlpha;
				NextFadeColor = Fade.FadeColor;
			}
        }

		// Apply Level Sequence Fade higher
		FHazeFadeSettings LevelSequenceSettings = AHazeLevelSequenceActor::GetFadeSettingsForFadeManagerComponent(this);
		if (LevelSequenceSettings.FadeAlpha > NextFadeAlpha)
		{
			NextFadeColor = LevelSequenceSettings.FadeColor;
			NextFadeAlpha = LevelSequenceSettings.FadeAlpha;
		}

		// If we're in a loading screen, always fully fade
		if (!LoadingScreenFadeColor.IsSet())
			LoadingScreenFadeColor = SceneView::GetPlayerOverlayColor(OwningPlayer);

		if (Game::IsInLoadingScreen())
		{
			if (CVar_HazeFadeOutOnLoadingScreen.GetInt() != 0)
			{
				NextFadeColor = LoadingScreenFadeColor.GetValue();
				NextFadeAlpha = 1.0;

				LoadingScreenRemainingFrames = EXTRA_LOADING_SCREEN_FADE_FRAMES;
				bIsFadingFromLoading = true;
			}
		}
		else if (LoadingScreenRemainingFrames > 0)
		{
			// Stay black for a couple of frames after a loading screen to give time for things to pop into place
			if (!Game::IsPausedForAnyReason())
				LoadingScreenRemainingFrames -= 1;

			NextFadeAlpha = 1.0;
			NextFadeColor = LoadingScreenFadeColor.GetValue();

			if (LoadingScreenRemainingFrames == 0 && OwningPlayer != nullptr)
			{
				AddFadeToColor(n"LoadingScreenFadeIn", LoadingScreenFadeColor.GetValue(), 0.0, 0.0, LOADING_SCREEN_FADE_IN_LENGTH, EFadePriority::Gameplay);
				Timer::SetTimer(this, n"OnFadeFromLoadComplete", LOADING_SCREEN_FADE_IN_LENGTH, false);
			}
		}
		else if (CurrentFadeAlpha > 0.0)
		{
			LoadingScreenFadeColor = NextFadeColor;
		}
		else
		{
			LoadingScreenFadeColor = FLinearColor::Black;
		}

        // Update the player's actual fade overlay
        CurrentFadeAlpha = NextFadeAlpha;

		CurrentFadeColor = NextFadeColor;
		CurrentFadeColor.A = CurrentFadeAlpha;

		if (OwningPlayer != nullptr)
        	SceneView::SetPlayerOverlayColor(OwningPlayer, CurrentFadeColor);
		else if(OwningMenuCameraUser != nullptr)
			OwningMenuCameraUser.SetFadeOverlayColor(CurrentFadeColor);
    }

	void SnapOutLoadingScreenFade()
	{
		LoadingScreenRemainingFrames = 0;
		bIsFadingFromLoading = false;
		ClearFade(n"LoadingSreenFadeIn", 0.0);
		SceneView::SetPlayerOverlayColor(OwningPlayer, FLinearColor::Transparent);
	}

	UFUNCTION()
	void OnFadeFromLoadComplete()
	{
		if(!Game::IsInLoadingScreen())
			bIsFadingFromLoading = false;
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        UpdateFades(DeltaSeconds);
    }
};