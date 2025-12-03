UCLASS(Abstract, HideCategories = "ComponentTick ComponentReplication Debug Activation Variable Cooking Disable Tags AssetUserData Collision")
class UDragonSwordUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Dragon Sword")
	TSubclassOf<ADragonSword> WeaponClass;

	ADragonSword Weapon;
	TArray<FHazePlayingAnimationData> ActiveAnimations;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Dragon Sword|Pin To Ground")
	UForceFeedbackEffect SwordPinImpactRumble;

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;
	private UPlayerMovementComponent MoveComp;
	private UPlayerTargetablesComponent TargetablesComp;

	TArray<FInstigator> SwordActivationInstigators;
	TArray<FInstigator> SwordShowInstigators;

	FVector PreviousSwordLocation;

	bool bHasBlockedCapabilities;
	bool bIsOnBack = false;
	bool bIsSequenceActive = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	void CreateSword()
	{
		if (Weapon != nullptr)
			return;

		Weapon = SpawnActor(WeaponClass);
		Weapon.AddActorCollisionBlock(this);
		Weapon.AddActorVisualsBlock(this);
		MoveSwordToBack();
	}

	bool IsWeaponEquipped() const
	{
		return (Weapon.AttachParentActor == Player && SwordIsActive());
	}

	bool SwordIsActive() const
	{
		return SwordActivationInstigators.Num() > 0;
	}

	UFUNCTION(BlueprintCallable)
	void ActivateSword(FInstigator ActivationInstigator)
	{
		SwordActivationInstigators.AddUnique(ActivationInstigator);
		MoveSwordToHand();
		AddShowSwordInstigator(ActivationInstigator);
	}

	UFUNCTION(BlueprintCallable)
	void MoveSwordToBack()
	{
		Weapon.AttachToComponent(Player.Mesh, DragonSword::BackSocket, EAttachmentRule::SnapToTarget);
		Weapon.SwordMesh.RelativeRotation = DragonSword::BackMeshRelativeRotation;
		Weapon.SwordMesh.RelativeLocation = DragonSword::BackMeshRelativeLocation;
		if (!bHasBlockedCapabilities)
		{
			Player.BlockCapabilities(DragonSwordCapabilityTags::DragonSwordCamera, this);
			Player.BlockCapabilities(DragonSwordCapabilityTags::DragonSwordCombat, this);
		}
		bHasBlockedCapabilities = true;
		bIsOnBack = true;
	}

	UFUNCTION(BlueprintCallable)
	void MoveSwordToHand()
	{
		const FTransform Transform = Player.Mesh.GetSocketTransform(DragonSword::HandSocket);
		Weapon.ActorLocation = Transform.Location;
		Weapon.ActorRotation = FRotator::MakeFromZX(-Transform.Rotation.RightVector, Transform.Rotation.UpVector);
		Weapon.SwordMesh.RelativeRotation = DragonSword::HandMeshRelativeRotation;
		Weapon.SwordMesh.RelativeLocation = FVector::ZeroVector;
		Weapon.AttachToComponent(Player.Mesh, DragonSword::HandSocket, EAttachmentRule::KeepWorld);
		if (bHasBlockedCapabilities)
		{
			Player.UnblockCapabilities(DragonSwordCapabilityTags::DragonSwordCamera, this);
			Player.UnblockCapabilities(DragonSwordCapabilityTags::DragonSwordCombat, this);
		}
		bHasBlockedCapabilities = false;
		bIsOnBack = false;
	}

	void AddShowSwordInstigator(FInstigator Instigator)
	{
		if (SwordShowInstigators.Num() == 0)
			Weapon.RemoveActorVisualsBlock(this);

		SwordShowInstigators.AddUnique(Instigator);
	}
	void RemoveShowSwordInstigator(FInstigator Instigator)
	{
		SwordShowInstigators.Remove(Instigator);
		if (SwordShowInstigators.Num() <= 0)
			Weapon.AddActorVisualsBlock(this);
	}

	UFUNCTION(BlueprintCallable)
	void DeactivateSword(FInstigator ActivationInstigator)
	{
		SwordActivationInstigators.RemoveSingleSwap(ActivationInstigator);
		MoveSwordToBack();
		RemoveShowSwordInstigator(ActivationInstigator);
	}

	FVector GetRootMotion(FVector& AccumulatedTranslation, float CurrentTime, float TotalMovementLength, float Duration) const
	{
		FVector RootMovement;
		if (ActiveAnimations.Num() > 0)
		{
			const UAnimSequenceBase Sequence = ActiveAnimations[0].Sequence;
			const FVector TotalMoveTranslation = FVector::ForwardVector * TotalMovementLength;
			RootMovement += Sequence.GetDeltaMoveForMoveRatio(AccumulatedTranslation, CurrentTime, TotalMoveTranslation, Duration);
		}
		return RootMovement;
	}
}