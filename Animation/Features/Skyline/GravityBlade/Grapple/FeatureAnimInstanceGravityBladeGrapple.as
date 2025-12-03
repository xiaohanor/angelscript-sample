UCLASS(Abstract)
class UFeatureAnimInstanceGravityBladeGrapple : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGravityBladeGrapple Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGravityBladeGrappleAnimData AnimData;

	// Add Custom Variables Here

	UGravityBladeUserComponent BladeComp;
	UGravityBladeGrappleUserComponent GrappleComp;

	UPlayerMovementComponent MoveComp;

	FGravityBladeGrappleAnimationData GravityBladeAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasThrown;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsTransition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPulling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanding;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float GrappleStateAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HorizontalAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector GrappleTargetDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float GrappleTargetAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TransitionPicker;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ThrownBlendSpaceValue;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGravityBladeGrapple NewFeature = GetFeatureAsClass(ULocomotionFeatureGravityBladeGrapple);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		BladeComp = UGravityBladeUserComponent::Get(Player);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.06;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		GravityBladeAnimData = GrappleComp.AnimationData;

		bIsGrounded = GravityBladeAnimData.bGrappleGrounded;
		//bHasThrown = GravityBladeAnimData.GrappleThrewThisFrame();
		bIsPulling = GravityBladeAnimData.GrapplePulledThisFrame();
		bIsTransition = GravityBladeAnimData.GrappleTransitionedThisFrame();
		bIsLanding = GravityBladeAnimData.GrappleLandedThisFrame();
		GrappleStateAlpha = GravityBladeAnimData.GrappleStateAlpha;
		

		if (CheckValueChangedAndSetBool(bHasThrown, GravityBladeAnimData.GrappleThrewThisFrame(), TriggerDirection = EHazeCheckBooleanChangedDirection::FalseToTrue))
		{

			// Calculate the angle between target and player for steep or shallow transitions/landings
			GrappleTargetDirection = (HazeOwningActor.ActorLocation - GrappleComp.ActiveGrappleData.WorldLocation);
			GrappleTargetDirection.Normalize();
			GrappleTargetAngle = GrappleComp.ActiveGrappleData.WorldUp.DotProduct(GrappleTargetDirection);
			
			VerticalAngle = GrappleTargetDirection.DotProduct(HazeOwningActor.ActorUpVector) * -1;

			HorizontalAngle = GrappleComp.ActiveGrappleData.WorldUp.DotProduct(HazeOwningActor.ActorRightVector);
			auto InitialGrappleDistance = (HazeOwningActor.ActorLocation - GrappleComp.ActiveGrappleData.WorldLocation).Size();

			// Print("InitialGrappleDistance: " + InitialGrappleDistance, 3.f);
			// Print("HorizontalAngle: " + HorizontalAngle, 3.f);
			// Print("VerticalAngle: " + VerticalAngle, 3.f);
			// Print("GrappleTargetAngle: " + GrappleTargetAngle, 3.f);
			// Print("ThrownBlendSpaceValue: " + ThrownBlendSpaceValue, 3.f);
			/*
			
			// If Short
			if (InitialGrappleDistance < 1100)
			{
				TransitionPicker = 0;
			}
			// If Far
			else if (InitialGrappleDistance > 1800)
			{
				if (VerticalAngle >= 0.5)
					TransitionPicker = 3;
				else 
				{
					// Left Right
					if (HorizontalAngle > 0.5)
						TransitionPicker = 5;
					else if (HorizontalAngle < -0.5)
						TransitionPicker = 6;
					else	
						TransitionPicker = Math::RandRange(5, 6);
				}
			}
			// If Medium
			else
			{
				if (VerticalAngle >= 0.5)
					TransitionPicker = 4;
				else 
				{
					if (HorizontalAngle > 0.5)
						TransitionPicker = 1;
					else if (HorizontalAngle < -0.5)
						TransitionPicker = 2;
					else	
						TransitionPicker = Math::RandRange(1, 2);
				}
			}		
				
			*/

			// Check distance to target and play different animations 
			if (InitialGrappleDistance > 2000 && VerticalAngle < 0.5)
				if (HorizontalAngle > 0.5)
					TransitionPicker = 5;
				else if (HorizontalAngle < -0.5)
					TransitionPicker = 6;
				else	
					TransitionPicker = Math::RandRange(5, 6);
			
			else if (InitialGrappleDistance > 1200 && VerticalAngle >= 0.5)		
				TransitionPicker = 3;
			else if (InitialGrappleDistance > 1200 && VerticalAngle < 0.5)	
			{
				if (HorizontalAngle > 0.5)
					TransitionPicker = 1;
				else if (HorizontalAngle < -0.5)
					TransitionPicker = 2;
				else	
					TransitionPicker = Math::RandRange(1, 2);
			}
			else
			{
				if (InitialGrappleDistance > 800 && VerticalAngle > 0.7)
					TransitionPicker = 4;
				else 
					TransitionPicker = 0;
			}
		}

		// Print("GrappleStateAlpha: " + GrappleStateAlpha, 0.f);
		//Print("GrappleTargetAngle: " + GrappleTargetAngle, 0.f);
		//Print("VerticalAngle: " + VerticalAngle, 0.f);

		// Lerping Blendspace value between initial throw angle and grapple angle
		ThrownBlendSpaceValue = GrappleTargetAngle * GrappleStateAlpha;
		ThrownBlendSpaceValue = Math::Clamp(ThrownBlendSpaceValue, VerticalAngle, GrappleTargetAngle);
		//Print("ThrownBlendSpaceValue NEW: " + ThrownBlendSpaceValue, 0.f);


		
		
		#if EDITOR	
			
			//Print("GrappleStateAlpha: " + GrappleStateAlpha, 0.f);
			//Print("TransitionPicker: " + TransitionPicker, 0.f);
			
			//Print("GrappleTargetAngle: " + GrappleTargetAngle, 0.f);
			
			//GravityBladeComp.ActiveGrappleData.RelativeRotation
			
		#endif
		


	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if (MoveComp.Velocity.Size2D() > SMALL_NUMBER)
			return true;

		if (LocomotionAnimationTag == n"GravityBladeCombat")
			return true;

		return TopLevelGraphRelevantAnimTimeRemaining < SMALL_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
		SetAnimFloatParam(n"MovementBlendTime", 0.3);
	}
}
