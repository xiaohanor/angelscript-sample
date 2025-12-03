class UIslandTopDownComponent : UActorComponent
{
	private bool bIsInTopDownMode = false;
	private bool bIsInFullscreen = false;
	private AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	bool IsInTopDownMode()
	{
		return bIsInTopDownMode;
	}

	void EnterTopDown(bool bFullscreen = true, EHazeViewPointBlendSpeed FullscreenBlend = EHazeViewPointBlendSpeed::Instant, AHazeCameraActor InitialCamera = nullptr, float CameraBlendTime = 0.0)
	{
		devCheck(!bIsInTopDownMode, "Tried to enter top down mode when we already are in top down mode.");
		Player.ApplyAiming2DPlaneConstraint(FVector::UpVector, this, EInstigatePriority::High);
		Player.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::TopDown, this, EInstigatePriority::High);

		if(InitialCamera != nullptr)
		{
			Player.ActivateCamera(InitialCamera, CameraBlendTime, this, EHazeCameraPriority::Medium);
		}

		if(bFullscreen)
		{
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, FullscreenBlend, EHazeViewPointPriority::High);
		}

		bIsInFullscreen = bFullscreen;
		bIsInTopDownMode = true;

		auto AnimLookAtComp = UHazeAnimPlayerLookAtComponent::Get(Player);
		if(AnimLookAtComp != nullptr)
			AnimLookAtComp.Disable(this);
	}

	void ExitTopDown()
	{
		devCheck(bIsInTopDownMode, "Tried to exit sidescroller when we haven't entered sidescroller mode.");
		Player.ClearAiming2DConstraint(this);
		Player.ClearGameplayPerspectiveMode(this);
		Player.DeactivateCameraByInstigator(this);

		if(bIsInFullscreen)
		{
			Player.ClearViewSizeOverride(this);
		}

		bIsInFullscreen = false;
		bIsInTopDownMode = false;

		auto AnimLookAtComp = UHazeAnimPlayerLookAtComponent::Get(Player);
		if(AnimLookAtComp != nullptr)
			AnimLookAtComp.ClearDisabled(this);
	}
}

namespace IslandTopDown
{
	UFUNCTION()
	void IslandEnterTopDown(AHazePlayerCharacter Player, bool bFullscreen = true, EHazeViewPointBlendSpeed FullscreenBlend = EHazeViewPointBlendSpeed::Instant, AHazeCameraActor InitialCamera = nullptr, float CameraBlendTime = 0.0)
	{
		auto TopDownComp = UIslandTopDownComponent::GetOrCreate(Player);
		TopDownComp.EnterTopDown(bFullscreen, FullscreenBlend, InitialCamera, CameraBlendTime);
	}

	UFUNCTION()
	void IslandExitTopDown(AHazePlayerCharacter Player)
	{
		auto TopDownComp = UIslandTopDownComponent::GetOrCreate(Player);
		TopDownComp.ExitTopDown();
	}
}