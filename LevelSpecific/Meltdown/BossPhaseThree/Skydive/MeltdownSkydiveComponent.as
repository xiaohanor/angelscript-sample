struct FMeltdownSkydiveAnimData
{
	FVector2D SkydiveInput;
	int BarrelRollDirection = 0;
	int HitReactionDirection = 0;
}

UCLASS(Abstract)
class UMeltdownSkydiveComponent : UActorComponent
{
	private TArray<FInstigator> SkydivingInstigators;
	private AHazePlayerCharacter PlayerOwner;
	private UPlayerMovementComponent MoveComp;

	EMeltdownPhaseThreeFallingWorld CurrentWorld;
	UMeltdownSkydiveSettings Settings;

	FVector CurrentHorizontalVelocity;
	FVector OriginLocation;
	float CurrentSkydiveHeight;
	float SkydiveStartTime;

	FMeltdownSkydiveAnimData AnimData;
	int CurrentHitReactionRequest = 0;

	bool bSkydiveOver = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(PlayerOwner);
		Settings = UMeltdownSkydiveSettings::GetSettings(PlayerOwner);
	}

	void StartSkydiving(FInstigator Instigator)
	{
		if(!IsSkydiving())
			CurrentHorizontalVelocity = MoveComp.HorizontalVelocity;

		SkydivingInstigators.AddUnique(Instigator);
		OriginLocation = (PlayerOwner.ActorLocation + PlayerOwner.OtherPlayer.ActorLocation) * 0.5;
		CurrentSkydiveHeight = OriginLocation.Z;
		SkydiveStartTime = Time::GameTimeSeconds;
		PlayerOwner.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::TopDown, this);
		MoveComp.TransitionCrumbSyncedPosition(this);

		auto VideoManager = UMeltdownBossPhaseFallingVideoManager::GetOrCreate(Game::Mio);
		VideoManager.StartSkydive();

		auto ShootingComp = UMeltdownGlitchShootingUserComponent::Get(PlayerOwner);
		ShootingComp.bGlitchShootingActive = false;
	}

	void StopSkydiving(FInstigator Instigator)
	{
		SkydivingInstigators.RemoveSingleSwap(Instigator);
		PlayerOwner.ClearGameplayPerspectiveMode(this);
	}

	void FinishSkydive()
	{
		bSkydiveOver = true;
		SkydivingInstigators.Empty();
		PlayerOwner.ClearGameplayPerspectiveMode(this);
	}

	bool IsSkydiving() const
	{
		return SkydivingInstigators.Num() > 0;
	}

	void ClearSkydivingInstigators()
	{
		SkydivingInstigators.Reset();
	}

	void RequestHitReaction(FVector SourceOfHit)
	{
		if(CurrentHitReactionRequest != 0)
			return;

		FVector LocalSourceOfHit = PlayerOwner.ActorTransform.InverseTransformPosition(SourceOfHit);
		CurrentHitReactionRequest = LocalSourceOfHit.Y > 0.0 ? -1 : 1;
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	float GetAccelerationWithDrag(float DeltaTime, float DragFactor, float MaxSpeed, float DragExponent = 1.0) const
	{
		const float IntegratedDragFactor = Math::Exp(-DragFactor);
		const float NewSpeed = MaxSpeed * Math::Pow(IntegratedDragFactor, DeltaTime);
		float Drag = Math::Abs(NewSpeed - MaxSpeed);

		// Optional, to make the drag more exponential. Might feel nicer
		if(DragExponent > 1.0 + KINDA_SMALL_NUMBER)
			Drag = Math::Pow(Drag, DragExponent);

		return Drag / DeltaTime;
	}
}

namespace MeltdownSkydive
{

UFUNCTION(DisplayName = "Meltdown Enable Skydive")
void EnableSkydive(AHazePlayerCharacter Player, FInstigator Instigator, UMeltdownSkydiveSettings SkydiveSettings, EHazeSettingsPriority SettingsPriority = EHazeSettingsPriority::Gameplay)
{
	if(SkydiveSettings != nullptr)
		Player.ApplySettings(SkydiveSettings, Instigator, SettingsPriority);

	auto SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
	SkydiveComp.StartSkydiving(Instigator);
}

UFUNCTION(DisplayName = "Meltdown Disable Skydive")
void DisableSkydive(AHazePlayerCharacter Player, FInstigator Instigator)
{
	Player.ClearSettingsOfClass(UMeltdownSkydiveSettings, Instigator);

	auto SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
	SkydiveComp.StopSkydiving(Instigator);
}

UFUNCTION(DisplayName = "Meltdown Finish Skydive")
void FinishSkydive(AHazePlayerCharacter Player)
{
	auto SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
	SkydiveComp.FinishSkydive();
}

UFUNCTION(DisplayName = "Meltdown Skydive Request Hit Reaction")
void RequestHitReaction(AHazePlayerCharacter Player, FVector SourceHit)
{
	auto SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
	SkydiveComp.RequestHitReaction(SourceHit);
}

}