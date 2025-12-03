struct FTundraCrackRootElevatorAnimData
{
	float VerticalAlpha;
}

UCLASS(Abstract)
class ATundraCrackRootElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditInstanceOnly)
	ATundraRangedLifeGivingActor LifeGivingActor;

	UPROPERTY(EditAnywhere)
	AActor CeilingClimbActorToAttach;

	UPROPERTY(EditAnywhere)
	FName BoneToAttachTo = n"Stalk8";

	UPROPERTY(DefaultComponent, EditAnywhere)
	UNiagaraComponent ElevatorVFX;

	bool bVFXActive = false;

	FTundraCrackRootElevatorAnimData AnimData;

	UFUNCTION(BlueprintPure)
	float GetVerticalAlpha()
	{
		return AnimData.VerticalAlpha;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AnimData.VerticalAlpha = LifeGivingActor.LifeReceivingComponent.VerticalAlpha;

		if(CeilingClimbActorToAttach != nullptr)
			CeilingClimbActorToAttach.AttachToComponent(Mesh, BoneToAttachTo, EAttachmentRule::KeepWorld);
		
		ElevatorVFX.AttachToComponent(Mesh, BoneToAttachTo, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AnimData.VerticalAlpha = LifeGivingActor.LifeReceivingComponent.VerticalAlpha;

		if(LifeGivingActor.LifeReceivingComponent.LifeForce >= 0.6 && !bVFXActive)
		{
			ElevatorVFX.Activate();
			bVFXActive = true;
		}
		else if(LifeGivingActor.LifeReceivingComponent.LifeForce < 0.6 && bVFXActive)
		{
			ElevatorVFX.Deactivate();
			bVFXActive = false;
		}
	}
}