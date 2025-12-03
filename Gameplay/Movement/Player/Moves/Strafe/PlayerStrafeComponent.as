
class UPlayerStrafeComponent : UActorComponent
{
	UPROPERTY()
	UPlayerStrafeSettings Settings;

	UPROPERTY(BlueprintReadOnly)
	FPlayerStrafeAnimData AnimData;

	TInstigated<USceneComponent> CurrentTarget;
	TArray<FInstigator> StrafeEnablers;

	float StrafeYawOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerStrafeSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	UFUNCTION(BlueprintPure)
	bool IsStrafeEnabled() const
	{
		return StrafeEnablers.Num() != 0;
	}

	void SetStrafeEnabled(FInstigator Instigator, bool bEnabled)
	{
		bool bWasEnabled = IsStrafeEnabled();
		if (bEnabled)
			StrafeEnablers.AddUnique(Instigator);
		else
			StrafeEnablers.Remove(Instigator);

		bool bNewEnabled = IsStrafeEnabled();

		if (!bNewEnabled && bWasEnabled)
			AnimData = FPlayerStrafeAnimData();
	}

	void ResetStrafe()
	{
		AnimData = FPlayerStrafeAnimData();
	}

	FRotator GetDefaultFacingRotation(AHazePlayerCharacter Player) const
	{
		FVector WorldUp = Player.MovementWorldUp;
		FRotator TargetFacingRotation = Player.GetCameraDesiredRotation();
		FVector ForwardVector = TargetFacingRotation.ForwardVector.VectorPlaneProject(WorldUp).GetSafeNormal();

		USceneComponent CurrentTargetComponent = CurrentTarget.Get();
		if(CurrentTargetComponent != nullptr)
		{
			FVector Dir = CurrentTargetComponent.GetWorldLocation() - Player.GetActorLocation();
			ForwardVector = Dir.VectorPlaneProject(WorldUp).GetSafeNormal();
		}

		if(ForwardVector.IsNearlyZero())
			ForwardVector = Player.GetActorForwardVector();

		return FRotator::MakeFromXZ(ForwardVector, WorldUp);
	}
}

struct FPlayerStrafeAnimData
{
	UPROPERTY()
	FVector2D BlendSpaceVector;

	UPROPERTY()
	bool bHasInput = false;

	UPROPERTY()
	EStrafeStationaryTurnMode StationaryTurnMode = EStrafeStationaryTurnMode::Step;

	UPROPERTY(Category = Smooth)
	float StationarySmoothTurnRate = 0.0;

	UPROPERTY(Category = Step)
	bool bTurning = false;

	UPROPERTY(Category = Step)
	float StationaryStepInitialAngle = 0.0;

	UPROPERTY(Category = Step)
	float StationaryStepTargetAngle = 0.0;

	UPROPERTY(Category = Step)
	float StationaryStepTurnAlpha = 0.0;

	bool bKeepOrientationInMh = true;

	UPROPERTY(Category = InitialTurn)
	ELeftRight InitialTurnDirection;
}

enum EStrafeStationaryTurnMode
{
	Smooth,
	Step
}

UFUNCTION(DisplayName = "Enable Player Strafe")
mixin void EnableStrafe(AHazePlayerCharacter Player, FInstigator Instigator)
{
	if (Player == nullptr)
		return;
	UPlayerStrafeComponent::GetOrCreate(Player).SetStrafeEnabled(Instigator, true);
}

UFUNCTION(DisplayName = "Disable Player Strafe")
mixin void DisableStrafe(AHazePlayerCharacter Player, FInstigator Instigator)
{
	if (Player == nullptr)
		return;

	UPlayerStrafeComponent StrafeComp = UPlayerStrafeComponent::Get(Player);
	if(StrafeComp == nullptr)
		return;

	StrafeComp.SetStrafeEnabled(Instigator, false);
}

UFUNCTION(DisplayName = "Is Player Strafe Enabled")
mixin bool IsStrafeEnabled(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return false;

	UPlayerStrafeComponent StrafeComp = UPlayerStrafeComponent::Get(Player);
	if(StrafeComp == nullptr)
		return false;

	return StrafeComp.IsStrafeEnabled();
}

UFUNCTION(DisplayName = "Apply Player Strafe Speed Scale")
mixin void ApplyStrafeSpeedScale(AHazePlayerCharacter Player, FInstigator Instigator, float Scale = 0.8)
{
	if (Player == nullptr)
		return;

	UPlayerStrafeSettings::SetStrafeMoveScale(Player, Scale, Instigator);
}

UFUNCTION(DisplayName = "Clear Player Strafe Speed Scale")
mixin void ClearStrafeSpeedScale(AHazePlayerCharacter Player, FInstigator Instigator)
{
	if (Player == nullptr)
		return;

	UPlayerStrafeSettings::ClearStrafeMoveScale(Player, Instigator);
}


UFUNCTION(DisplayName = "Apply Player Strafe Speed Scale")
mixin void ApplyStrafeTarget(AHazePlayerCharacter Player, USceneComponent Target, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	if (Player == nullptr)
		return;
	if (Target == nullptr)
		return;
	UPlayerStrafeComponent StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
	StrafeComp.CurrentTarget.Apply(Target, Instigator, Priority);
}

UFUNCTION(DisplayName = "Clear Player Strafe Speed Scale")
mixin void ClearStrafeTarget(AHazePlayerCharacter Player, FInstigator Instigator)
{
	if (Player == nullptr)
		return;

	UPlayerStrafeComponent StrafeComp = UPlayerStrafeComponent::Get(Player);
	if(StrafeComp == nullptr)
		return;
	
	StrafeComp.CurrentTarget.Clear(Instigator);
}

UFUNCTION(DisplayName = "Set Player Strafe Yaw Offset")
mixin void SetStrafeYawOffset(AHazePlayerCharacter Player, float InStrafeYawOffset)
{
	if (Player == nullptr)
		return;

	UPlayerStrafeComponent StrafeComp = UPlayerStrafeComponent::Get(Player);
	if(StrafeComp == nullptr)
		return;
	
	StrafeComp.StrafeYawOffset = InStrafeYawOffset;
}

UFUNCTION(DisplayName = "Set Keep Orientation In Mh")
mixin void SetStrafeKeepOrientationInMh(AHazePlayerCharacter Player, bool inbKeepOrientationInMh)
{
	if (Player == nullptr)
		return;

	UPlayerStrafeComponent StrafeComp = UPlayerStrafeComponent::Get(Player);
	if(StrafeComp == nullptr)
		return;
	
	StrafeComp.AnimData.bKeepOrientationInMh = inbKeepOrientationInMh;
}