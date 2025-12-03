UCLASS(Abstract, HideCategories = "ComponentTick ComponentReplication Debug Activation Variable Cooking Disable Tags AssetUserData Collision")
class UGravityBladeUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade")
	TSubclassOf<AGravityBladeActor> BladeClass;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBladeActor Blade;
	TArray<FHazePlayingAnimationData> ActiveAnimations;

	UPROPERTY(EditAnywhere)
	UHazeLocomotionFeatureBundle FeatureBundle;
	UPROPERTY(EditAnywhere)
	UAnimSequence SheatheAnimation;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset SheatheAnimationBoneFilter;

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;
	private UPlayerMovementComponent MoveComp;
	private UPlayerTargetablesComponent TargetablesComp;
	private bool bBladeSheathed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	
		AimComp = UPlayerAimingComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);

		Blade = SpawnActor(BladeClass);
		const FTransform Transform = Player.Mesh.GetSocketTransform(GravityBlade::AttachSocket);
		Blade.ActorLocation = Transform.Location;
		Blade.ActorRotation = FRotator::MakeFromZX(-Transform.Rotation.RightVector, Transform.Rotation.UpVector);
		Blade.AttachToComponent(Player.Mesh, GravityBlade::AttachSocket, EAttachmentRule::KeepWorld);

		Player.Mesh.AddLocomotionFeatureBundle(FeatureBundle, this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(Blade != nullptr)
		{
			Blade.DetachRootComponentFromParent();
			Blade.DestroyActor();
			Blade = nullptr;
		}
	}
	
	void EquipBlade(float InterpTime = -1.0)
	{
		if (!IsValid(Blade))
			return;

		if (IsBladeEquipped())
		{
			devError(f"Weapon is already equipped.");
			return;
		}

		Blade.DetachRootComponentFromParent();

		if (InterpTime > 0.0)
			Blade.OffsetComponent.FreezeTransformAndLerpBackToParent(this, InterpTime);

		if (bBladeSheathed)
		{
			Blade.AttachToComponent(Player.Mesh, GravityBlade::SheathedAttachSocket, EAttachmentRule::SnapToTarget);
			Blade.SetActorRelativeTransform(GravityBlade::SheathedAttachTransform);
		}
		else
		{
			const FTransform Transform = Player.Mesh.GetSocketTransform(GravityBlade::AttachSocket);
			Blade.ActorLocation = Transform.Location;
			Blade.ActorRotation = FRotator::MakeFromZX(-Transform.Rotation.RightVector, Transform.Rotation.UpVector);
			Blade.AttachToComponent(Player.Mesh, GravityBlade::AttachSocket, EAttachmentRule::KeepWorld);
		}
	}

	void UnequipBlade()
	{
		if (!IsBladeEquipped())
		{
			devError(f"Weapon is not currently equipped.");
			return;
		}

		Blade.DetachRootComponentFromParent();

		// Unhide primitives on the gravity blade in case they got hidden by camera clipping
		TArray<UPrimitiveComponent> Primitives;
		Blade.GetComponentsByClass(Primitives);
		for (auto Primitive : Primitives)
		{
			if (Primitive != nullptr)
			{
				Primitive.SetBasePassRenderedForPlayer(Player, true);
				Primitive.SetBasePassRenderedForPlayer(Player.OtherPlayer, true);
			}
		}
	}

	UFUNCTION(DevFunction)
	void SheatheBlade(bool bPlaySheatheAnimation = true)
	{
		if (bBladeSheathed)
			return;

		bBladeSheathed = true;
		Player.Mesh.RemoveLocomotionFeatureBundle(FeatureBundle, this);

		if (SheatheAnimation != nullptr && bPlaySheatheAnimation)
		{
			Player.PlayOverrideAnimation(
				FHazeAnimationDelegate(),
				SheatheAnimation,
				BoneFilterAsset = SheatheAnimationBoneFilter, BlendTime = 0.1, BlendOutTime = 0.2,
				Priority = EHazeAnimPriority::AnimPrio_SlotAnimation);
			Timer::SetTimer(this, n"OnSheatheCompleted", 0.12);
		}
		else
		{
			if (bPlaySheatheAnimation)
				Blade.OffsetComponent.FreezeTransformAndLerpBackToParent(this, GravityBlade::SheatheLerpDuration);
			OnSheatheCompleted();
		}
	}

	UFUNCTION()
	private void OnSheatheCompleted()
	{
		if (!IsBladeEquipped())
			return;
		if (!bBladeSheathed)
			return;

		Blade.AttachToComponent(Player.Mesh, GravityBlade::SheathedAttachSocket, EAttachmentRule::SnapToTarget);
		Blade.SetActorRelativeTransform(GravityBlade::SheathedAttachTransform);
	}

	UFUNCTION(DevFunction)
	void UnsheatheBlade(bool bLerp = true)
	{
		if (!bBladeSheathed)
			return;

		bBladeSheathed = false;
		if (IsBladeEquipped())
		{	
			if (bLerp)
				Blade.OffsetComponent.FreezeTransformAndLerpBackToParent(this, GravityBlade::UnsheatheLerpDuration);

			const FTransform Transform = Player.Mesh.GetSocketTransform(GravityBlade::AttachSocket);
			Blade.ActorLocation = Transform.Location;
			Blade.ActorRotation = FRotator::MakeFromZX(-Transform.Rotation.RightVector, Transform.Rotation.UpVector);
			Blade.AttachToComponent(Player.Mesh, GravityBlade::AttachSocket, EAttachmentRule::KeepWorld);
		}

		Player.Mesh.AddLocomotionFeatureBundle(FeatureBundle, this);
	}

	bool IsBladeSheathed() const
	{
		return bBladeSheathed;
	}

	bool IsBladeSpawned() const
	{
		if(Blade == nullptr)
			return false;
		
		return true;
	}


	bool IsBladeEquipped() const
	{
		if(!IsBladeSpawned())
			return false;
		
		return (Blade.AttachParentActor == Player);
	}

	FVector GetLinearMotionBeforeHit(
		float FrameStartTime, float DeltaTime,
		float MovementLength, float Duration
	)
	{
		if (ActiveAnimations.Num() == 0)
			return FVector::ZeroVector;

		UAnimSequenceBase Sequence = ActiveAnimations[0].Sequence;
		FVector TotalMoveTranslation = FVector::ForwardVector * MovementLength;

		float TimeForAnimationToHit = Math::Max(Sequence.GetAnimNotifyStateStartTime(UAnimNotifyGravityBladeHitWindow), 0.05);
		float TimeAtStart = Math::Min(FrameStartTime, Math::Min(TimeForAnimationToHit, Duration));
		float TimeAtEnd = Math::Min(FrameStartTime + DeltaTime, Math::Min(TimeForAnimationToHit, Duration));

		FVector TranslationAtStart = TotalMoveTranslation * (TimeAtStart / TimeForAnimationToHit);
		FVector TranslationAtEnd = TotalMoveTranslation * (TimeAtEnd / TimeForAnimationToHit);
		return TranslationAtEnd - TranslationAtStart;
	}

	FVector GetRootMotionBeforeHit(
		float FrameStartTime, float DeltaTime,
		float MovementLength, float Duration) const
	{
		if (ActiveAnimations.Num() == 0)
			return FVector::ZeroVector;

		UAnimSequenceBase Sequence = ActiveAnimations[0].Sequence;
		FVector TotalMoveTranslation = FVector::ForwardVector * MovementLength;

		float TimeForAnimationToHit = Math::Max(Sequence.GetAnimNotifyStateStartTime(UAnimNotifyGravityBladeHitWindow), 0.05);
		float TimeAtStart = Math::Min(FrameStartTime, Math::Min(TimeForAnimationToHit, Duration));
		float TimeAtEnd = Math::Min(FrameStartTime + DeltaTime, Math::Min(TimeForAnimationToHit, Duration));

		float RatioAtHit = Sequence.GetMoveRatioAtTime(TimeForAnimationToHit, Duration).X;
		float RatioAtStart = Sequence.GetMoveRatioAtTime(TimeAtStart, Duration).X;
		float RatioAtEnd = Sequence.GetMoveRatioAtTime(TimeAtEnd, Duration).X;

		if (RatioAtHit <= 0)
			return FVector::ZeroVector;

		FVector TranslationAtStart = TotalMoveTranslation * (RatioAtStart / RatioAtHit);
		FVector TranslationAtEnd = TotalMoveTranslation * (RatioAtEnd / RatioAtHit);
		return TranslationAtEnd - TranslationAtStart;
	}

	FVector GetRootMotionAfterHit(
		float FrameStartTime, float DeltaTime,
		float MovementLength, float Duration) const
	{
		if (ActiveAnimations.Num() == 0)
			return FVector::ZeroVector;

		UAnimSequenceBase Sequence = ActiveAnimations[0].Sequence;
		FVector TotalMoveTranslation = FVector::ForwardVector * MovementLength;

		float TimeForAnimationToHit = Math::Max(Sequence.GetAnimNotifyStateStartTime(UAnimNotifyGravityBladeHitWindow), 0.05);
		float TimeAtStart = Math::Min(Math::Max(FrameStartTime, TimeForAnimationToHit), Duration);
		float TimeAtEnd = Math::Min(Math::Max(FrameStartTime + DeltaTime, TimeForAnimationToHit), Duration);

		float RatioAtHit = Sequence.GetMoveRatioAtTime(TimeForAnimationToHit, Duration).X;
		float RatioAtStart = Sequence.GetMoveRatioAtTime(TimeAtStart, Duration).X;
		float RatioAtEnd = Sequence.GetMoveRatioAtTime(TimeAtEnd, Duration).X;

		if (RatioAtHit >= 1)
			return FVector::ZeroVector;

		FVector TranslationAtStart = TotalMoveTranslation * (RatioAtStart / (1.0 - RatioAtHit));
		FVector TranslationAtEnd = TotalMoveTranslation * (RatioAtEnd / (1.0 - RatioAtHit));
		return TranslationAtEnd - TranslationAtStart;
	}

	FVector GetRootMotionForFullAnimation(
		float FrameStartTime, float DeltaTime,
		float MovementLength, float Duration) const
	{
		if (ActiveAnimations.Num() == 0)
			return FVector::ZeroVector;

		UAnimSequenceBase Sequence = ActiveAnimations[0].Sequence;
		FVector TotalMoveTranslation = FVector::ForwardVector * MovementLength;

		float TimeForAnimationToHit = Math::Max(Sequence.GetAnimNotifyStateStartTime(UAnimNotifyGravityBladeHitWindow), 0.05);
		float TimeAtStart = Math::Min(Math::Max(FrameStartTime, 0), Duration);
		float TimeAtEnd = Math::Min(Math::Max(FrameStartTime + DeltaTime, 0), Duration);

		float RatioAtStart = Sequence.GetMoveRatioAtTime(TimeAtStart, Duration).X;
		float RatioAtEnd = Sequence.GetMoveRatioAtTime(TimeAtEnd, Duration).X;

		FVector TranslationAtStart = TotalMoveTranslation * RatioAtStart;
		FVector TranslationAtEnd = TotalMoveTranslation * RatioAtEnd;
		return TranslationAtEnd - TranslationAtStart;
	}
}