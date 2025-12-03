UCLASS(Meta = (HighlightPlacement))
class APlayerWallRunVolume : AVolume
{
	default BrushComponent.LineThickness = 4.0;

	UPROPERTY(Category = Settings, EditAnywhere, BlueprintReadOnly)
	EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay;

	/*
	- 0 will stop wall run from activating
	- 2 will double the weight of the wall run activated etc
	*/
	UPROPERTY(Category = Settings, EditAnywhere, BlueprintReadOnly, meta = (ClampMin = "0.0", UIMin = "0.0"))
	float WallRunWeight = 1.0;

	UPROPERTY(Category = Settings, EditAnywhere, BlueprintReadOnly)
	EPlayerWallRunJumpOverride JumpOverride;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UPlayerWallRunComponent WallRunComp = UPlayerWallRunComponent::Get(Player);
		if (WallRunComp == nullptr)
			return;

		UPlayerWallRunSettings Settings = UPlayerWallRunSettings();
		Settings.bOverride_ActivationWeight = true;
		Settings.ActivationWeight = WallRunWeight;

		if (JumpOverride != EPlayerWallRunJumpOverride::None)
		{
			Settings.bOverride_JumpOverride = true;
			Settings.JumpOverride = JumpOverride;
		}

		Player.ApplySettings(Settings, this, Priority);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Player.ClearSettingsByInstigator(this);
	}
}