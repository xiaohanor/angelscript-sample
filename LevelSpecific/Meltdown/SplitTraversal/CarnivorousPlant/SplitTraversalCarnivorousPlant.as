event void FSplitTraversalCableTargeted();

enum ECarnivorousPlantState
{
	Following,
	LockedTarget,
	Attacking,
	Sleeping
}

struct FSplitTraversalRobotArmRotation
{
	UPROPERTY(EditAnywhere, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float Arm1Rotation;

	UPROPERTY(EditAnywhere, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float Arm2Rotation;

	UPROPERTY(EditAnywhere, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float HeadRotation;

	UPROPERTY(EditAnywhere, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float Jaw1Rotation;

	UPROPERTY(EditAnywhere, Meta = (UIMin = "-180.0", UIMax = "180.0"))
	float Jaw2Rotation;
};

class ASplitTraversalCarnivorousPlant : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CarnivorousPlantRoot;

	UPROPERTY(DefaultComponent, Attach = CarnivorousPlantRoot)
	USceneComponent CarnivorousHeadRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RobotArmRoot;

	UPROPERTY(DefaultComponent, Attach = RobotArmRoot)
	USceneComponent RobotClawRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent InRangeTriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent OutOfRangeTriggerComp;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalCutableCable CableActor;

	UPROPERTY()
	FSplitTraversalCableTargeted OnCableTargeted;

	UPROPERTY(EditAnywhere)
	FHazePointOfInterestFocusTargetInfo POITargetInfoZoe;

	UPROPERTY(EditAnywhere)
	FHazePointOfInterestFocusTargetInfo POITargetInfoMio;

	UPROPERTY(BlueprintReadOnly)
	bool bCableTargeted = false;

	UPROPERTY()
	float FollowStateDuration = 3.0;

	UPROPERTY()
	float LockedTargetStateDuration = 2.5;

	UPROPERTY()
	float FollowSpeed = 2.0;

	UPROPERTY(EditAnywhere)
	float CutCableYaw = 225.0;

	UPROPERTY()
	float TargetCableMargin = 5.0;

	UPROPERTY()
	bool bZoeInRange = false;

	UPROPERTY()
	bool bActivated = false;

	UPROPERTY()
	FSplitTraversalRobotArmRotation Rotation;

	ECarnivorousPlantState State = ECarnivorousPlantState::Sleeping;
	float FollowUntilGameTime;
	float LockedTargetUntilGameTime;

	FHazeAcceleratedRotator AcceleratedRotation;
	FRotator TargetRotation;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		RobotArmRoot.SetWorldLocation(CarnivorousPlantRoot.WorldLocation + FVector::ForwardVector * 500000.0);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		InRangeTriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"InRange");
		OutOfRangeTriggerComp.OnComponentEndOverlap.AddUFunction(this, n"OutOfRange");

		AcceleratedRotation.SnapTo(CarnivorousPlantRoot.GetWorldRotation());
		TargetRotation = CarnivorousPlantRoot.GetWorldRotation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedRotation.AccelerateTo(TargetRotation, FollowSpeed, DeltaSeconds);
		CarnivorousPlantRoot.SetWorldRotation(AcceleratedRotation.Value);
		RobotArmRoot.SetWorldRotation(AcceleratedRotation.Value);

		if (State == ECarnivorousPlantState::Following)
		{
			FVector FlattenVector = FVector(1.0, 1.0, 0.0);
			TargetRotation = ((Game::Zoe.ActorLocation * FlattenVector) - (CarnivorousPlantRoot.WorldLocation * FlattenVector)).GetSafeNormal().Rotation();

			if (Time::GameTimeSeconds > FollowUntilGameTime && HasControl())
				CrumbLockedTarget();
		}

		if (State == ECarnivorousPlantState::LockedTarget)
		{
			CarnivorousHeadRoot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Sin(Time::GameTimeSeconds * 25.0) * 10.0));

			if (Time::GameTimeSeconds > LockedTargetUntilGameTime && HasControl())
				CrumbAttack(TargetRotation);
		}

		if (State == ECarnivorousPlantState::Attacking)
		{
			
		}

		if (State == ECarnivorousPlantState::Sleeping)
		{
			CarnivorousHeadRoot.SetRelativeRotation(FRotator(Math::Sin(Time::GameTimeSeconds * 2.0) * 20.0, 0.0, 0.0));
		}
	}

	UFUNCTION(CrumbFunction)
	protected void CrumbFollow()
	{
		State = ECarnivorousPlantState::Following;

		CarnivorousHeadRoot.SetRelativeRotation(FRotator::ZeroRotator);
		FollowUntilGameTime = Time::GameTimeSeconds + FollowStateDuration;
	}

	UFUNCTION(CrumbFunction)
	protected void CrumbLockedTarget()
	{
		State = ECarnivorousPlantState::LockedTarget;

		LockedTargetUntilGameTime = Time::GameTimeSeconds + LockedTargetStateDuration;
	}

	UFUNCTION(CrumbFunction)
	protected void CrumbAttack(FRotator CrumbTargetRotation)
	{
		State = ECarnivorousPlantState::Attacking;
		
		float Angle = CrumbTargetRotation.ForwardVector.GetAngleDegreesTo(CableActor.FantasyExplosionRoot.WorldLocation - CarnivorousPlantRoot.WorldLocation);

		if (Angle < TargetCableMargin && !CableActor.bCableCut)
		{
			TargetRotation = FRotator(0.0, CutCableYaw, 0.0);
			bCableTargeted = true;
			OnCableTargeted.Broadcast();
		}
		else
			bCableTargeted = false;

		BP_Attack();
	}

	UFUNCTION(CrumbFunction)
	protected void CrumbSleeping()
	{
		State = ECarnivorousPlantState::Sleeping;
		
	}

	UFUNCTION()
	void Activate()
	{
		if (bActivated)
			return;

		bActivated = true;
		CrumbFollow();
		BP_Activated();
	}

	UFUNCTION()
	private void InRange(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                     UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                     const FHitResult&in SweepResult)
	{
		if (OtherActor == Game::Zoe && !bZoeInRange)
		{
			bZoeInRange = true;
		}

		Activate();
	}

	UFUNCTION()
	private void OutOfRange(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (OtherActor == Game::Zoe && bZoeInRange)
		{
			bZoeInRange = false;
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Attack()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activated()
	{
	}
};