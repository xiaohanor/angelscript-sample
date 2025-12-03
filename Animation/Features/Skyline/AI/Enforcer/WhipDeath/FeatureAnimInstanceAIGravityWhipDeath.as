UCLASS(Abstract)
class UFeatureAnimInstanceAIGravityWhipDeath : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAIGravityWhipDeath Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAIGravityWhipDeathAnimData AnimData;

	UEnforcerDamageComponent DamageComp;


	UPROPERTY(BlueprintReadOnly, Category = "Cached Data")
	EHazeCardinalDirection PushDirection;

	UPROPERTY(BlueprintReadOnly, Category = "Cached Data")
	EHazeCardinalDirection PushHitDirection;

	UPROPERTY(BlueprintReadOnly, Category = "Cached Data")
	EHazeCardinalDirection HitDirection;

	UPROPERTY(BlueprintReadOnly, Category = "Cached Data")
	EAnimHitPitch HitPitch;

	UPROPERTY()
	float HitPitchBlendValue = 0;

	UPROPERTY()
	float HitDirectionBlendValue = 0;

	UPROPERTY()
	FVector2D PushDirectionBlendValue = FVector2D::ZeroVector;

	UPROPERTY()
	float DeathStartPosition;

	UPROPERTY()
	bool bDiedInAir = false;

	bool bFirstFrame;
	
	//* Sperring madness
	TArray<FName> BonesToHide;

	FName HiddenBone;

	UHazeSkeletalMeshComponentBase Mesh;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{

		AHazeCharacter Character = Cast<AHazeCharacter>(HazeOwningActor);
		Mesh = Character.Mesh;

		BonesToHide.Add(n"Head");
		BonesToHide.Add(n"Spine");
		BonesToHide.Add(n"RightForeArm");
		BonesToHide.Add(n"LeftForeArm");
		BonesToHide.Add(n"RightLeg");
		BonesToHide.Add(n"LeftLeg");
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
			ULocomotionFeatureAIGravityWhipDeath NewFeature = GetFeatureAsClass(ULocomotionFeatureAIGravityWhipDeath);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;

			DamageComp = UEnforcerDamageComponent::GetOrCreate(HazeOwningActor);
		}

			if (Feature == nullptr)
				return;

		bFirstFrame = true;

		// TODO: This should not be done in anim instance, move to death capability		
		int RandomIndex = Math::RandRange(0, BonesToHide.Num() - 1);
		HiddenBone = BonesToHide[RandomIndex];
		//Mesh.HideBoneByName(HiddenBone, EPhysBodyOp::PBO_None);
		FEnforcerEffectOnDeathData Data;
		Data.DismemberedBones.Add(HiddenBone);
		UEnforcerEffectHandler::Trigger_OnDeath(HazeOwningActor, Data);

		if (bIsInAir)
			bDiedInAir = true;

		
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		return 0.05;
	}

	
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

	
		//* Set when to end death-feature	
		if (!bFirstFrame && TopLevelGraphRelevantAnimTimeRemaining <= 0.1)
		{	
			AnimComp.ClearPrioritizedFeatureTag(Feature.Tag);
		}
		bFirstFrame = false;

		
		if (DamageComp == nullptr)
			return;
		
		PushDirection = CardinalDirectionForActor(HazeOwningActor, DamageComp.PushDirection);
		PushHitDirection = CardinalDirectionForActor(HazeOwningActor, DamageComp.PushHitDirection);
		HitDirection = DamageComp.HitDirection;
		HitPitch = DamageComp.HitPitch;		

		//* Set HitDirections
		switch (HitDirection)
		{
			case EHazeCardinalDirection::Forward : 
			{
				HitPitchBlendValue = 1;
				break;
			}
			case EHazeCardinalDirection::Backward :
			{
				HitPitchBlendValue = 1;
				break;
			}
			case EHazeCardinalDirection::Right :
			{
				HitDirectionBlendValue = 1;
				break;
			}
			case EHazeCardinalDirection::Left :
			{
				HitDirectionBlendValue = -1;
				break;
			}
		}

		switch (HitPitch)
		{
			case EAnimHitPitch::Center : 
			{
				HitPitchBlendValue = 0;
				break;
			}
			case EAnimHitPitch::Up :
			{
				HitPitchBlendValue = 1;
				break;
			}
			case EAnimHitPitch::Down :
			{
				HitPitchBlendValue = -1;
				break;
			}
		}

		switch (PushDirection)
		{
			case EHazeCardinalDirection::Forward : 
			{
				PushDirectionBlendValue.Y = 1;
				break;
			}
			case EHazeCardinalDirection::Backward :
			{
				PushDirectionBlendValue.Y = -1;
				break;
			}
			case EHazeCardinalDirection::Right :
			{
				PushDirectionBlendValue.X = 1;
				break;
			}
			case EHazeCardinalDirection::Left :
			{
				PushDirectionBlendValue.X = -1;
				break;
			}
		}


		//* Prints0.f);
		#if EDITOR	
		/*
			Print("bDiedInAir: " + bDiedInAir, 0.f);
			Print("PushDirection: " + PushDirection, 0.f);
			Print("PushHitDirection: " + PushHitDirection, 0.f);
			Print("HitDirection: " + HitDirection, 0.f);
			DamageComp.HealthComp.GetHealthFraction();
			Print("DamageComp.HealthComp.GetHealthFraction();: " + DamageComp.HealthComp.GetHealthFraction(), 0.f);

			Print("DeathStartPosition: " + DeathStartPosition, 0.f);
		*/
		#endif	

	}	

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		Mesh.UnHideBoneByName(HiddenBone);
	}

	/*
	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return TopLevelGraphRelevantAnimTimeRemaining <= 0.5;
	}
	*/
	
}