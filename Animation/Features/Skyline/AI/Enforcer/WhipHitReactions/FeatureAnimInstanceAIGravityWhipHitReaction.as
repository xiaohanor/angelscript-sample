namespace SubTagGravityWhipHitReaction
{
	const FName Grapple = n"Grapple";
}

UCLASS(Abstract)
class UFeatureAnimInstanceAIGravityWhipHitReaction : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAIGravityWhipHitReaction Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAIGravityWhipHitReactionAnimData AnimData;

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
	float HitReactionStartPosition;

	UPROPERTY()
	bool bIsGrappleHit = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureAIGravityWhipHitReaction NewFeature = GetFeatureAsClass(ULocomotionFeatureAIGravityWhipHitReaction);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;

			DamageComp = UEnforcerDamageComponent::GetOrCreate(HazeOwningActor);
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		return 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);
		
		if (DamageComp == nullptr)
			return;
		
		bIsGrappleHit = IsCurrentSubTag(SubTagGravityWhipHitReaction::Grapple);

		PushDirection = CardinalDirectionForActor(HazeOwningActor, DamageComp.PushDirection);
		PushHitDirection = CardinalDirectionForActor(HazeOwningActor, DamageComp.PushHitDirection);
		HitDirection = DamageComp.HitDirection;
		HitPitch = DamageComp.HitPitch;

		//HitReactionStartPosition = ((DamageComp.HealthComp.GetHealthFraction() - 1) * -1) * 0.2;
		

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
				PushDirectionBlendValue.X = 0;
				break;
			}
			case EHazeCardinalDirection::Left :
			{
				PushDirectionBlendValue.X = 0;
				break;
			}
		}

		if (!bIsInAir)
			{
				HitDirectionBlendValue *= 0.4;
				HitPitchBlendValue *= 0.4;
				// HitDirectionBlendValue *= ((DamageComp.HealthComp.GetHealthFraction() - 1) * -1) + 0.1;
				// HitPitchBlendValue *= ((DamageComp.HealthComp.GetHealthFraction() - 1) * -1) + 0.1;
				HitReactionStartPosition = 0.4;
			}
		else
			HitReactionStartPosition = 0.05;




		//* Prints0.f);
		#if EDITOR	
		/*
			Print("PushDirection: " + PushDirection, 0.f);
			Print("PushHitDirection: " + PushHitDirection, 0.f);
			Print("HitPitchBlendValue: " + HitPitchBlendValue, 0.f);
			Print("HitDirection: " + HitDirection, 0.f);
			Print("DamageComp.HealthComp.GetHealthFraction();: " + DamageComp.HealthComp.GetHealthFraction(), 0.f);

			Print("HitReactionStartPosition: " + HitReactionStartPosition, 0.f);
		*/
		#endif	

	}	
}