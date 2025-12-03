event void FOnStatueStartedFalling();
class AIceKingStatue : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PedestalMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UForceFeedbackComponent FFComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USquishTriggerBoxComponent SquishTrigger;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedSmoothProgress;	

	UPROPERTY(EditInstanceOnly)
	ATundraRangedLifeGivingActor LifeGivingActor;

	UPROPERTY()
	FOnStatueStartedFalling OnStatueStartedFalling;

	UTreeGuardianHoldDownIceKingComponent HoldDownIceKingComponent;
	bool bStartedFalling = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HoldDownIceKingComponent = UTreeGuardianHoldDownIceKingComponent::GetOrCreate(Game::Zoe);
		LifeGivingActor.AttachToComponent(Mesh, AttachmentRule = EAttachmentRule::KeepWorld);
		LifeGivingActor.RangedTargetable.OnCommitInteract.AddUFunction(this, n"OnInteractionStart");
		SetActorControlSide(Game::GetZoe());

		if(HasControl())
			HoldDownIceKingComponent.OnMashCompleted.AddUFunction(this, n"CrumbStatueStartedFalling");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			float Progress = Game::GetZoe().GetButtonMashProgress(HoldDownIceKingComponent);
			if(bStartedFalling)
				Progress = 1.0;

			SyncedSmoothProgress.SetValue(Math::FInterpTo(SyncedSmoothProgress.Value, Progress, DeltaSeconds, 2));

			float Delta = Math::Abs(Progress - SyncedSmoothProgress.Value) / DeltaSeconds;
			
			float FFStrength = Math::GetMappedRangeValueClamped(FVector2D(0, 20), FVector2D(0, 1), Delta);
			float LeftFF = FFStrength;
			float RightFF = FFStrength;
			Game::Zoe.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
		}
		
		FRotator NewRot;
		NewRot.Pitch = Math::Lerp(0, -22.5, SyncedSmoothProgress.Value);
		MeshRoot.SetRelativeRotation(NewRot);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStatueStartedFalling(bool bIsIceKing)
	{
		if(bIsIceKing)
			return;
		
		Timer::SetTimer(this, n"DelayedStartedFalling", 0.5);
		Timer::SetTimer(this, n"DelayedDisable", 1.2);
		bStartedFalling = true;
	}

	UFUNCTION()
	private void DelayedStartedFalling()
	{
		SetActorTickEnabled(false);
		OnStatueStartedFalling.Broadcast();
		Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	}

	UFUNCTION()
	private void DelayedDisable()
	{
		LifeGivingActor.RangedTargetable.ForceExitInteract();
		LifeGivingActor.RangedTargetable.Disable(this);
		FFComp.Play();
	}

	UFUNCTION()
	void OnInteractionStart()
	{
		SetActorTickEnabled(true);
	}
}