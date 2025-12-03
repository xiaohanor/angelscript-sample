
struct FGameShowArenaMovingPlatformMoveParams
{
	FGameShowArenaMovingPlatformMoveParams(FVector InStartLocation, FVector InTargetLocation, float InMoveDuration)
	{
		StartLocation = InStartLocation;
		TargetLocation = InTargetLocation;
		MoveDuration = InMoveDuration;
	}
	FVector StartLocation;
	FVector TargetLocation;
	float MoveDuration;
}

class UGameShowArenaMovingPlatformMoveCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FGameShowArenaMovingPlatformMoveParams MoveParams;
	AGameShowArenaMovingPlatform MovingPlatform;

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FGameShowArenaMovingPlatformMoveParams Params)
	{
		MoveParams = Params;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovingPlatform = Cast<AGameShowArenaMovingPlatform>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > MoveParams.MoveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FGameShowArenaMovingPlatformMovingStoppedParams Params;
		Params.MovingPlatform = MovingPlatform;
		UGameShowArenaMovingPlatformEventHandler::Trigger_StopMoving(MovingPlatform, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovingPlatform.CurrentMoveDirection = (MoveParams.TargetLocation - MoveParams.StartLocation).GetSafeNormal();
		MovingPlatform.UpdateDecalRotation();
		MovingPlatform.SetActorLocation(MoveParams.TargetLocation);
		FGameShowArenaMovingPlatformMovingStartedParams Params;
		Params.MovingPlatform = MovingPlatform;
		UGameShowArenaMovingPlatformEventHandler::Trigger_StartMoving(MovingPlatform, Params);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector NewLocation = Math::Lerp(MoveParams.StartLocation, MoveParams.TargetLocation, Math::SinusoidalInOut(0, 1, ActiveDuration / MoveParams.MoveDuration));
		MovingPlatform.SetActorLocation(NewLocation);
	}
}

class AGameShowArenaMovingPlatform : AGameShowArenaDynamicObstacleBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseArm;
	default BaseArm.RelativeLocation = FVector::ZeroVector;
	default BaseArm.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = BaseArm)
	UStaticMeshComponent LowerArm;
	default LowerArm.RelativeLocation = FVector(0, 0, LowerArmOffset);
	default LowerArm.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = LowerArm)
	UStaticMeshComponent UpperArm;
	default UpperArm.RelativeRotation = FRotator::ZeroRotator;
	default UpperArm.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = UpperArm)
	UStaticMeshComponent PlatformArm;
	default PlatformArm.RelativeLocation = FVector(0, 0, PlatformArmOffset);
	default PlatformArm.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = PlatformArm)
	UStaticMeshComponent PlatformMesh;
	default PlatformMesh.RelativeLocation = FVector(0, 0, PlatformOffset);

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGameShowArenaHeightAdjustableComponent HeightAdjustableComp;

	UPROPERTY(DefaultComponent)
	UGameShowArenaDisplayDecalPlatformComponent DisplayDecalComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UGameShowArenaPlatformPlayerReactionCapability);

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface PanelMaterial;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "!bShouldGlitch"))
	float MoveToTargetDuration = 2;

	UPROPERTY(EditInstanceOnly)
	FVector TargetOffset;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "!bShouldGlitch"))
	float MoveToStartDuration = 2;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "!bShouldGlitch"))
	float WaitDuration = 2;

	UPROPERTY(EditInstanceOnly)
	bool bShowDecal = true;

	UPROPERTY(EditInstanceOnly)
	bool bSynchronizeWithBombPickup = true;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D Texture;

	UPROPERTY(EditAnywhere)
	bool bIsAlternateDecal;

	float WaitTimer = 0;

	bool bIsAtOffset = false;
	bool bHasUpdatedDecalRotation = false;

	UPROPERTY(EditInstanceOnly)
	bool bShouldGlitch = false;

	FRotator DecalRotation = FRotator::ZeroRotator;

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaBombHolder ConnectedBombHolder;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	bool bBombHasExploded = false;

	FVector CurrentMoveDirection;

	FVector StartLocation;
	FVector TargetLocation;

	const float PlatformArmOffset = 390;
	const float PlatformOffset = 110;
	const float LowerArmOffset = 80;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		TargetLocation = ActorLocation + TargetOffset;
		if (!bSynchronizeWithBombPickup && HasControl())
		{
			ActionQueueComp.Empty();
			ActionQueueComp.SetLooping(true);
			ActionQueueComp.Capability(UGameShowArenaMovingPlatformMoveCapability, FGameShowArenaMovingPlatformMoveParams(StartLocation, TargetLocation, MoveToTargetDuration));
			ActionQueueComp.Idle(WaitDuration);
			ActionQueueComp.Capability(UGameShowArenaMovingPlatformMoveCapability, FGameShowArenaMovingPlatformMoveParams(TargetLocation, StartLocation, MoveToStartDuration));
			ActionQueueComp.Idle(WaitDuration);
		}

		DisplayDecalComp.AssignTarget(PlatformMesh, PanelMaterial);
		CurrentMoveDirection = TargetOffset.GetSafeNormal();
		UpdateDecalRotation();

		if (bSynchronizeWithBombPickup)
		{
			ConnectedBombHolder.OnBombPickedUp.AddUFunction(this, n"OnBombPickedUp");
			ConnectedBombHolder.ConnectedBomb.OnBombStartExploding.AddUFunction(this, n"OnBombExploded");
			if (bShowDecal)
				DisplayDecalComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(PlatformMesh.WorldLocation, DecalRotation, FVector::OneVector * 150, Texture, DecalColor = FLinearColor::Green), bIsAlternateDecal);

			HeightAdjustableComp.ComponentTickEnabled = false;
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void OnBombExploded(AGameShowArenaBomb Bomb)
	{
		bBombHasExploded = true;
	}

	UFUNCTION()
	void FlipDecalRotation()
	{
		DecalRotation = FRotator::MakeFromX(-CurrentMoveDirection);
	}

	UFUNCTION()
	void UpdateDecalRotation()
	{
		if (bShouldGlitch || !bShowDecal)
			return;

		DecalRotation = FRotator::MakeFromX(CurrentMoveDirection);
	}

	UFUNCTION()
	private void OnBombPickedUp()
	{
		bBombHasExploded = false;
		SetActorTickEnabled(true);
		if (!HasControl())
			return;

		ActionQueueComp.Empty();
		ActionQueueComp.SetLooping(true);

		ActionQueueComp.Capability(UGameShowArenaMovingPlatformMoveCapability, FGameShowArenaMovingPlatformMoveParams(StartLocation, TargetLocation, MoveToTargetDuration));
		ActionQueueComp.Idle(WaitDuration * 0.5);
		ActionQueueComp.Event(this, n"FlipDecalRotation");
		ActionQueueComp.Idle(WaitDuration * 0.5);
		ActionQueueComp.Event(this, n"CheckShouldStop");

		ActionQueueComp.Capability(UGameShowArenaMovingPlatformMoveCapability, FGameShowArenaMovingPlatformMoveParams(TargetLocation, StartLocation, MoveToStartDuration));
		ActionQueueComp.Idle(WaitDuration * 0.5);
		ActionQueueComp.Event(this, n"FlipDecalRotation");
		ActionQueueComp.Idle(WaitDuration * 0.5);
		ActionQueueComp.Event(this, n"CheckShouldStop");
	}

	UFUNCTION()
	void CheckShouldStop()
	{
		if (bBombHasExploded && HasControl())
		{
			bool bShouldStop = ActorLocation.IsWithinDist(StartLocation, 5);
			if (bShouldStop)
			{
				SetActorTickEnabled(false);
				ActionQueueComp.Empty();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bShouldGlitch || !bShowDecal)
			return;

		DisplayDecalComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(PlatformMesh.WorldLocation, DecalRotation, FVector::OneVector * 150, Texture, DecalColor = FLinearColor::Green), bIsAlternateDecal);
	}
};