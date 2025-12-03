UCLASS(Abstract)
class UFeatureAnimInstanceGravityWhip : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGravityWhip Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGravityWhipAnimData AnimData;

	// Add Custom Variables Here

	UGravityWhipUserComponent GravWhipComp;

	UPlayerMovementComponent MoveComp;

	UPlayerStrafeComponent StrafeComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FGravityWhipAnimationData GravWhipAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D PullDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D TensionVector;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector ObjectRelativePosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector InitialObjRelativePos;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalAimSpaceValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HorizontalAimSpaceValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ObjectDistance;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int WhipInt;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGrabbedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAirGrabbedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bAttachedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasGrabbedObject;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasTurnedIntoWhipHit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWhipGrabHadTarget;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bNotInLassoState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsThrowing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsReleasing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bisMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingWhip;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSlingableObject;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInThrow;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBlockOverride;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ThrowStartPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHitGloryKill;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTorHammerAttackStart;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTorHammerAttackEnd;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData ActiveGloryKill;

	bool bCameFromAttach;
	
	bool bCameFromPull;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingMeshUpperBodyOverrideAnimation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingLocalUpperBodyOverrideAnimation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRollDashLocalUpperBodyOverrideAnimation;;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset FullBodyBoneFilter;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset UpperBodyBoneFilter;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset NullBoneFilter;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset RightArmBoneFilter;
	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BothArmFilter;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGravityWhip NewFeature = GetFeatureAsClass(ULocomotionFeatureGravityWhip);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		GravWhipComp = UGravityWhipUserComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		StrafeComp = UPlayerStrafeComponent::Get(Player);

		StrafeComp.StrafeYawOffset = 0;

		bSlingableObject = false;

		bInEnter = true;	

		

		TArray<AActor>  AttachedActors;
		Player.GetAttachedActors(AttachedActors);
		if (GravWhipComp.Whip != nullptr)
		{
			GravWhipComp.Whip.SetAnimIntParam(n"WhipInt", WhipInt);
		}

		//bHasGrabbedObject = GravWhipComp.GetNumGrabbedComponents() > 0;

		bCameFromAttach = false;
		bCameFromPull = false;
		ThrowStartPosition = 0.0;

		CopyAnimBoneTransforms(n"RightAttach", n"RightHand_IK", bCopyTranslation = false);

		GravWhipComp.bIsHolstered = false;
	}

	FVector ObjectPrevPos;
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
	
		//* Variables
		SetAnimBoolParam(n"RequestingFullBodyOverride", true);
		bBlockOverride = GetAnimBoolParam(n"RequestingBlockOverrideAnimation");
		bIsRequestingMeshUpperBodyOverrideAnimation = GetAnimBoolParam(n"RequestingMeshUpperBodyOverrideAnimation");
		bIsRequestingLocalUpperBodyOverrideAnimation = GetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation");
		if (bIsRequestingLocalUpperBodyOverrideAnimation && (LocomotionAnimationTag == n"StrafeDash" || LocomotionAnimationTag == n"Dash"))
			bRollDashLocalUpperBodyOverrideAnimation = true;
		else
			bRollDashLocalUpperBodyOverrideAnimation = false;

		VerticalAimSpaceValue = GravWhipComp.AnimationData.VerticalAimSpace;
		HorizontalAimSpaceValue = GravWhipComp.AnimationData.HorizontalAimSpace;
		GravWhipAnimData = GravWhipComp.AnimationData;

		TensionVector = (GravWhipComp.AnimationData.TensionPullDirection2D.GetSafeNormal() * GravWhipAnimData.Tension);

		bGrabbedThisFrame = GravWhipAnimData.GrabbedThisFrame();
		bAirGrabbedThisFrame = GravWhipAnimData.AirGrabbedThisFrame();
		bAttachedThisFrame = GravWhipAnimData.GrabAttachedThisFrame();

		bIsThrowing = GravWhipAnimData.ThrownThisFrame();
		bIsReleasing = GravWhipAnimData.ReleasedThisFrame();

		bIsRequestingWhip = GravWhipAnimData.bIsRequestingWhip;

		bHasGrabbedObject = GravWhipComp.GetNumGrabbedComponents() > 0;
		bHasTurnedIntoWhipHit = GravWhipAnimData.bHasTurnedIntoWhipHit;
		bWhipGrabHadTarget = GravWhipComp.bWhipGrabHadTarget;

		bHitGloryKill = GravWhipComp.ActiveGloryKill.IsSet();
		if (bHitGloryKill)
			ActiveGloryKill = GravWhipComp.ActiveGloryKill.Value.Sequence.PlayerAnimation;

		bTorHammerAttackStart = GravWhipComp.bTorHammerAttackStart;
		bTorHammerAttackEnd = GravWhipComp.bTorHammerAttackEnd;

		bNotInLassoState = TopLevelGraphRelevantStateName != n"Lasso";

		if (bAirGrabbedThisFrame || bGrabbedThisFrame)
		{
			InitialObjRelativePos = (GravWhipComp.GrabCenterLocation - Player.ActorCenterLocation);	

			InitialObjRelativePos = Player.ActorRotation.UnrotateVector(InitialObjRelativePos);
			InitialObjRelativePos.Normalize();
			
			if (WhipInt < 4)
				WhipInt++;
			else
				WhipInt = 0;				
		}

		bisMoving = MoveComp.Velocity.Size() >= SMALL_NUMBER;

		if ((GravWhipComp.GetPrimaryGrabMode() == EGravityWhipGrabMode::Sling))
			bSlingableObject = true;

		if (TopLevelGraphRelevantStateName == "Enter")
			bInEnter = true;
		else 
			bInEnter = false;

		if (TopLevelGraphRelevantStateName == "Throw")
		{
			bInThrow = true;
		}
		else 
		{
			bInThrow = false;
		}

		if (bCameFromAttach)
			ThrowStartPosition = 0.5;
		else		
		{
			ThrowStartPosition = 0.0;
		}

		// if (bIsThrowing)
		// 	WhipInt = Math::RandRange(0, 1);

		//*Get object relative position for blendspace
		FVector WhipTargetLocation = GetWhipTarget();

		if (ObjectPrevPos == FVector::ZeroVector)
			ObjectPrevPos = WhipTargetLocation;
		FVector ObjectSpeed = (ObjectPrevPos - WhipTargetLocation) / DeltaTime / 1.0;
		ObjectPrevPos = WhipTargetLocation;
		

		ObjectRelativePosition = (WhipTargetLocation - Player.ActorCenterLocation);

		ObjectRelativePosition = Player.ActorRotation.UnrotateVector(ObjectRelativePosition);

		ObjectDistance = ObjectRelativePosition.Size();
		
		ObjectRelativePosition.Normalize();

		
		if (!bSlingableObject)
		{
			PullDirection.Y = ObjectRelativePosition.Z;
			PullDirection.X = ObjectRelativePosition.Y;
			TensionVector = PullDirection + TensionVector;
		}	
		else
		{ 
			ObjectRelativePosition.X *= -1;
			ObjectRelativePosition.Y -= 0.82;
			ObjectRelativePosition.Y *= -4;
			TensionVector = PullDirection + TensionVector;
			TensionVector *= 0.7;
		}

		if (GravWhipComp.Whip != nullptr)
		{
			GravWhipComp.Whip.SetAnimVectorParam(n"WhipTargetPos", ObjectRelativePosition);
			GravWhipComp.Whip.SetAnimVectorParam(n"WhipInitialTargetPos", InitialObjRelativePos);
			GravWhipComp.Whip.SetAnimIntParam(n"WhipInt", WhipInt);
			GravWhipComp.Whip.SetAnimBoolParam(n"WhipIsRequestingWhip", bIsRequestingWhip);
			GravWhipComp.Whip.SetAnimBoolParam(n"WhipSlingableObject", bSlingableObject);
			GravWhipComp.Whip.SetAnimBoolParam(n"WhipHasReleased", bIsReleasing);
			GravWhipComp.Whip.SetAnimBoolParam(n"WhipInEnter", bInEnter);
			GravWhipComp.Whip.SetAnimBoolParam(n"ZoeWhipInThrow", bInThrow);
			GravWhipComp.Whip.SetAnimVectorParam(n"WhipTargetLocation", WhipTargetLocation);
			GravWhipComp.Whip.SetAnimBoolParam(n"WhipHasGrabbedObject", bHasGrabbedObject);
			GravWhipComp.Whip.SetAnimBoolParam(n"WhipGrabHadTarget", bWhipGrabHadTarget);
			GravWhipComp.Whip.SetAnimBoolParam(n"HasTurnedIntoWhipHit", bHasTurnedIntoWhipHit);
			GravWhipComp.Whip.SetAnimFloatParam(n"ThrowStartPosition", ThrowStartPosition);
			GravWhipComp.Whip.SetAnimBoolParam(n"CameFromAttach", bCameFromAttach);
			GravWhipComp.Whip.SetAnimBoolParam(n"CameFromPull", bCameFromPull);
		}

		#if EDITOR
		
		/*
			Print("bisMoving: " + bisMoving, 0.f);
			
			Print("bRollDashLocalUpperBodyOverrideAnimation: " + bRollDashLocalUpperBodyOverrideAnimation, 0.f);
		Print("bIsRequestingLocalUpperBodyOverrideAnimation: " + bIsRequestingLocalUpperBodyOverrideAnimation, 0.f);
		Print("bRollDashLocalUpperBodyOverrideAnimation: " + bRollDashLocalUpperBodyOverrideAnimation, 0.f);
		//Print("bHitGloryKill: " + bHitGloryKill, 0.f);
		//Debug::DrawDebugCoordinateSystem(Game::Zoe.Mesh.GetSocketLocation(n"Align"), Game::Zoe.Mesh.GetSocketRotation(n"Align"), 100, 3);

		//Print("StrafeComp.AnimData.bTurning: " + StrafeComp.AnimData.bTurning, 0.f);
		//GravWhipComp.AnimationData.TargetComponents
		//GravWhipAnimData.NumGrabs
		/*
        Print("bCameFromAttach: " + bCameFromAttach, 0.f);
		Print("bCameFromPull: " + bCameFromPull, 0.f);
		Print("bIsThrowing: " + bIsThrowing, 0.f);
		Print("bIsReleasing: " + bIsReleasing, 0.f);
		Print("bHasGrabbedObject: " + bHasGrabbedObject, 0.f); // Emils Print
		Print("HasGrabbed: " + GravWhipAnimData.GrabbedThisFrame(), 0.f);
		Print("bIsRequestingWhip: " + bIsRequestingWhip, 0.f);
		Print("bWhipGrabHadTarget: " + bWhipGrabHadTarget, 0.f);
		PrintToScreenScaled("WhipInt: " + WhipInt, 0.f, Scale = 3.f); // Emils Print
		Print("GravWhipAnimData.bHasTurnedIntoWhipHit: " + GravWhipAnimData.bHasTurnedIntoWhipHit, 0.f);
		Print("bGrabbedThisFrame: " + bGrabbedThisFrame, 0.f); // Emils Print
		Print("bAirGrabbedThisFrame: " + bAirGrabbedThisFrame, 0.f); // Emils Print
		Print("bAttachedThisFrame: " + bAttachedThisFrame, 0.f);
		Print("GravWhipAnimData.VerticalAimSpace: " + GravWhipAnimData.VerticalAimSpace, 0.f);
		Print("GravWhipAnimData.HorizontalAimSpace: " + GravWhipAnimData.HorizontalAimSpace, 0.f);
		Print("bSlingableObject: " + bSlingableObject, 0.f);
		Print("bIsReleasing: " + GravWhipAnimData.ReleasedThisFrame(), 0.f);
		Print("bInThrow: " + bInThrow, 0.f); // Emils Print
		Print("GravWhipComp.GetNumGrabbedComponents(): " + GravWhipComp.GetNumGrabbedComponents(), 0.f); // Emils Print
		PrintToScreenScaled("GravWhipComp.TargetData.GrabMode: " + GravWhipComp.TargetData.GrabMode, 0.f); // Emils Print
		Print("ObjectRelativePosition: " + ObjectRelativePosition, 0.f);
		Print("AimSpaceValue: " + AimSpaceValue, 0.f);

			Print("PullDirection: " + PullDirection, 0.f);


		// Print("bNotInLassoState: " + bNotInLassoState, 0.f);
			Print("TensionVector: " + TensionVector, 0.f);

		Print("bisMoving: " + bisMoving, 0.f); // Emils Print
		*/
		#endif
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.06;
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTimeWhenResetting() const
	{
		return 0.06;
	}
	
	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here
		/*
		if ((TopLevelGraphRelevantStateName == "Enter") || (TopLevelGraphRelevantStateName == "Enter Move"))
			return TopLevelGraphRelevantAnimTimeRemaining < 0.1;
		*/
		if ((TopLevelGraphRelevantStateName == "Throw" || TopLevelGraphRelevantStateName == "Enter" || TopLevelGraphRelevantStateName == "Exit" || bGrabbedThisFrame || bAirGrabbedThisFrame) && bBlockOverride)
			return true;
		
		if (LocomotionAnimationTag == n"Grapple" || LocomotionAnimationTag == n"SwingAir")
			return true;

		if (LocomotionAnimationTag == n"LedgeMantle")
			return true;

		if (LocomotionAnimationTag == n"LadderClimb" || LocomotionAnimationTag == n"PoleClimb")
			return true;

		if (bisMoving && (TopLevelGraphRelevantStateName == n"Enter" || TopLevelGraphRelevantStateName == n"Throw"))
			return TopLevelGraphRelevantAnimTimeRemainingFraction <= 0.3;
		if (bisMoving && TopLevelGraphRelevantStateName == n"HitGloryKill")
			return TopLevelGraphRelevantAnimTimeRemainingFraction <= 0.5;

		/*
		if (OverrideFeatureTag != "GravityWhip")
			return true;
		*/

		else
			return ((TopLevelGraphRelevantAnimTimeRemaining <= 0.1 || LowestLevelGraphRelevantAnimTimeRemainingFraction <= 0.1));
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		SetAnimFloatParam(n"MovementBlendTime", 0.2);
		SetAnimBoolParam(n"RequestingBlockOverrideAnimation", false);
		SetAnimBoolParam(n"RequestingMeshUpperBodyOverrideAnimation", false);
		SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", false);
		SetAnimBoolParam(n"SlideJumping", false);
		SetAnimBoolParam(n"GravityWhipLanding", false);

		GravWhipComp.bIsHolstered = true;
	}

	FVector GetWhipTarget()
	{
		auto TargetComponents = GravWhipComp.AnimationData.TargetComponents;

		int NumComponents = 0;
		FVector AccumulatedLocation = FVector::ZeroVector;
		for (auto TargetComponent : TargetComponents)
		{
			if (TargetComponent == nullptr)
				continue;

			++NumComponents;
			AccumulatedLocation += TargetComponent.WorldLocation;
		}

		if (NumComponents == 0)
		{
			if (GravWhipComp.bIsAirGrabbing)
				return GravWhipComp.GrabCenterLocation;
			return FVector::ZeroVector;
		}

		return AccumulatedLocation / NumComponents;
	}


	UFUNCTION(BlueprintOverride)
	UHazeBoneFilterAsset GetOverrideBoneFilter(float32& OutBlendTime, bool& bOutUseMeshSpaceBlend) const
	{
		if (GetAnimBoolParam(n"GravityWhipLanding"))
		{
			OutBlendTime = 0.2;
			bOutUseMeshSpaceBlend = false;
			return RightArmBoneFilter;
		}
		if (!bisMoving && GetAnimBoolParam(n"IsInStrafeDash"))
		{
			OutBlendTime = 0.2;
			bOutUseMeshSpaceBlend = true;
			return UpperBodyBoneFilter;
		}
		
		if (!bisMoving && TopLevelGraphRelevantStateName != n"Lasso" && LocomotionAnimationTag != "Perch")
		{
			OutBlendTime = 0.2;
			return FullBodyBoneFilter;
		}

		if (bBlockOverride)
		{
			OutBlendTime = 0.2;
			return NullBoneFilter;
		}
		if (GetAnimBoolParam(n"SlideJumping") || GetAnimBoolParam(n"PerformingRollDashJump") || GetAnimBoolParam(n"PerformingAirJump"))
		{
			OutBlendTime = 0.2;
			bOutUseMeshSpaceBlend = false;
			return UpperBodyBoneFilter;
		}
		if (bRollDashLocalUpperBodyOverrideAnimation)
		{
			OutBlendTime = 0.2;
			bOutUseMeshSpaceBlend = false;
			return RightArmBoneFilter;
		}
		
		if ((bisMoving || LocomotionAnimationTag == n"Perch" || StrafeComp.AnimData.bTurning || bIsRequestingMeshUpperBodyOverrideAnimation) && LocomotionAnimationTag != n"StrafeDash")
		{
			OutBlendTime = 0.2;
			bOutUseMeshSpaceBlend = true;
			return UpperBodyBoneFilter;
		}	

			
		
		// return nullptr;

		OutBlendTime = 0.2;
		bOutUseMeshSpaceBlend = true;
		return UpperBodyBoneFilter;
		
	}
	
	
    UFUNCTION()
    void AnimNotify_CameFromPull()
    {
        bCameFromAttach = false;
		bCameFromPull = true;
    }

    UFUNCTION()
    void AnimNotify_CameFromAttach()
    {
        bCameFromAttach = true;
		bCameFromPull = false;
    }
	UFUNCTION()
    void AnimNotify_ClearAttachPull()
    {
        bCameFromAttach = false;
		bCameFromPull = false;
    }
}

class UGravityWhipHolsteredAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
	            FAnimNotifyEventReference EventReference) const
	{
		auto GravWhipComp = UGravityWhipUserComponent::Get(MeshComp.Owner);
		if (GravWhipComp != nullptr && GravWhipComp.GetPrimaryGrabMode() != EGravityWhipGrabMode::TorHammer)
			GravWhipComp.bIsHolstered = true;
		return true;
	}
}
