class AIslandRotationPlatform: AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent,  Attach = RootComp)
	USceneComponent RotationComp;
	UPROPERTY(DefaultComponent, Attach = RotationComp)
	UStaticMeshComponent PlatformMesh;
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = false;
	default DisableComp.AutoDisableRange = 8000.0;

	FHazeAcceleratedRotator AcceleratedRotator;

	UPROPERTY(EditAnywhere)
	FRotator TargetRotation;
	UPROPERTY(EditAnywhere)
	float ForwardStiffness = 10;
	UPROPERTY(EditAnywhere)
	float ForwardDampening = 0.8;
	UPROPERTY(EditAnywhere)
	float BackwardsStiffness = 5;
	UPROPERTY(EditAnywhere)
	float BackwardsDampening = 0.8;
	bool bMovingForward = false;
	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		

	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMovingForward)
		{
			AcceleratedRotator.SpringTo(TargetRotation, 1 * ForwardStiffness , 1 * ForwardDampening, DeltaSeconds);
		}
		else
		{
			AcceleratedRotator.SpringTo(StartRotation, 1 * BackwardsStiffness, 1 * BackwardsDampening, DeltaSeconds);
		}

		FHitResult HitResult;
		RotationComp.SetRelativeRotation(FRotator(AcceleratedRotator.Value.Pitch, AcceleratedRotator.Value.Yaw, AcceleratedRotator.Value.Roll), false, HitResult, false);
		//SetActorRotation(AcceleratedRotator.Value);
	}

	UFUNCTION()
	void ActivateForward()
	{
		bMovingForward = true;
		ActorTickEnabled = true;
	}
	UFUNCTION()
	void ReverseBackwards()
	{
		bMovingForward = false;
		ActorTickEnabled = true;
	}
}

