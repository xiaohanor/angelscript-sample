UCLASS(Abstract)
class ATundraCrackRootMonkeyHanger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere)
	AActor CeilingClimbActorToAttach;

	UPROPERTY(EditAnywhere)
	FName BoneToAttachTo = n"Stalk8";

	UTundraPlayerSnowMonkeyCeilingClimbComponent ClimbComp;
	FTundraCrackRootElevatorAnimData AnimData;
	default AnimData.VerticalAlpha = HighestAlpha;

	FHazeAcceleratedFloat AcceleratedAlpha;

	const float LowestAlpha = 0.2;
	const float HighestAlpha = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedAlpha.SnapTo(HighestAlpha);

		if(CeilingClimbActorToAttach != nullptr)
		{
			CeilingClimbActorToAttach.AttachToComponent(Mesh, BoneToAttachTo, EAttachmentRule::KeepWorld);
			ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(CeilingClimbActorToAttach);
			ClimbComp.OnAttach.AddUFunction(this, n"OnAttach");
			ClimbComp.OnDeatch.AddUFunction(this, n"OnDetach");
		}
	}

	UFUNCTION()
	private void OnAttach()
	{
		UTundraCrackRootMonkeyHangerEffectHandler::Trigger_OnStartHanging(this);
	}

	UFUNCTION()
	private void OnDetach()
	{
		UTundraCrackRootMonkeyHangerEffectHandler::Trigger_OnStopHanging(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float PreviousAlpha = AcceleratedAlpha.Value;
		if(ClimbComp == nullptr || !ClimbComp.IsMonkeyClimbingOn())
		{
			AcceleratedAlpha.AccelerateToWithStop(HighestAlpha, 3.0, DeltaTime, 0.01);
			if(!Math::IsNearlyEqual(PreviousAlpha, HighestAlpha) && Math::IsNearlyEqual(AcceleratedAlpha.Value, HighestAlpha))
				UTundraCrackRootMonkeyHangerEffectHandler::Trigger_OnReachedTop(this);
		}
		else
		{
			AcceleratedAlpha.AccelerateToWithStop(LowestAlpha, 1.5, DeltaTime, 0.01);
			if(!Math::IsNearlyEqual(PreviousAlpha, LowestAlpha) && Math::IsNearlyEqual(AcceleratedAlpha.Value, LowestAlpha))
				UTundraCrackRootMonkeyHangerEffectHandler::Trigger_OnReachedBottom(this);
		}

		AnimData.VerticalAlpha = AcceleratedAlpha.Value;
	}
}