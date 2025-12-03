enum ECoastBossPlayerDroneShield
{
	Normal,
	Invincible,
	Hurt,
	Down,
}

class ACoastBossPlayerDrone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh)
	UStaticMeshComponent ShipMeshTEMP;

	UPROPERTY(DefaultComponent)
	USceneComponent AttachPlayerToComponent;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = AttachPlayerToComponent)
	UHazeEditorPreviewSkeletalMeshComponent PlayerPreview;
	default PlayerPreview.PreviewVisibility = EHazeEditorPreviewSkeletalMeshVisibility::AlwaysVisible;
#endif

	UPROPERTY(DefaultComponent)
	USceneComponent ShootLocationComponent;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent InvulnerableShield;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterial NormalMaterial;
	UPROPERTY(EditDefaultsOnly)
	UMaterial InvincibleMaterial;
	UPROPERTY(EditDefaultsOnly)
	UMaterial HurtMaterial;
	UPROPERTY(EditInstanceOnly)
	EHazePlayer User;

	FVector OGScale;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InvulnerableShield.SetVisibility(false);
		OGScale = InvulnerableShield.RelativeScale3D;
	}

	UFUNCTION(BlueprintEvent)
	void OnStartShip()
	{
		
	}

	UFUNCTION(BlueprintCallable)
	void UpdatePlayerFacingDirection(FVector Direction, AHazePlayerCharacter Player)
	{
		Player.SetMovementFacingDirection(Direction);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ChangeShieldMaterial(ECoastBossPlayerDroneShield Type) {};

	UFUNCTION(CallInEditor)
	void SnapDoubleInteractActorToAttachPlayerToComponent()
	{
		AActor TrainCart = AttachParentActor;
		TArray<AActor> AttachedActors;
		TrainCart.GetAttachedActors(AttachedActors);
		for(AActor Actor : AttachedActors)
		{
			auto DoubleInteractionActor = Cast<ADoubleInteractionActor>(Actor);
			if(DoubleInteractionActor == nullptr)
				continue;

			UInteractionComponent RelevantInteractionComp;
			if(User == EHazePlayer::Mio)
			{
				RelevantInteractionComp = DoubleInteractionActor.ExclusiveMode == EDoubleInteractionExclusiveMode::LeftMioRightZoe ? DoubleInteractionActor.LeftInteraction : DoubleInteractionActor.RightInteraction;
			}
			else
			{
				RelevantInteractionComp = DoubleInteractionActor.ExclusiveMode == EDoubleInteractionExclusiveMode::LeftZoeRightMio ? DoubleInteractionActor.LeftInteraction : DoubleInteractionActor.RightInteraction;
			}

			RelevantInteractionComp.WorldLocation = AttachPlayerToComponent.WorldLocation;
		}
	}
};