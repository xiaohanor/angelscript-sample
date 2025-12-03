class UAnimNotifySetGravityWhipAttachAlpha : UAnimNotifyState
{
	UPROPERTY(EditAnywhere)
	const float Value = 1;

	UPROPERTY(EditAnywhere)
	const float InterpSpeedIn = 20;

	UPROPERTY(EditAnywhere)
	const float InterpSpeedOut = 20;

#if EDITOR
	default NotifyColor = FColor::Magenta;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GravityWhipAttachAlpha";
	}
	
	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
		if (HazeSkelMeshComp != nullptr) {
			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachAlpha", Value);
			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachAlphaInterpSpeed", InterpSpeedIn);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
		if (HazeSkelMeshComp != nullptr) {
			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachAlpha", 0);
			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachAlphaInterpSpeed", InterpSpeedOut);
		}

		return true;
	}
	
}

class UAnimNotifySetGravityWhipStretchAlpha : UAnimNotifyState
{
	UPROPERTY(EditAnywhere)
	const float Value = 1;

	UPROPERTY(EditAnywhere)
	const float InterpSpeedIn = 20;

	UPROPERTY(EditAnywhere)
	const float InterpSpeedOut = 20;

#if EDITOR
	default NotifyColor = FColor::Orange;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GravityWhipStretchAlpha";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
		if (HazeSkelMeshComp != nullptr) {
			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipStretchAlpha", Value);
			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachStretchAlphaSpeed", InterpSpeedIn);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
		if (HazeSkelMeshComp != nullptr) {
			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipStretchAlpha", 0);
			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachStretchAlphaSpeed", InterpSpeedOut);
		}

		return true;
	}

}



class UAnimInstanceGravityWhipWeapon : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Enter")   
    FHazePlaySequenceData EnterVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Enter")   
    FHazePlaySequenceData EnterVar1a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Enter")   
    FHazePlaySequenceData EnterVar2;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Enter")   
    FHazePlaySequenceData EnterVar2a;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Enter")   
    FHazePlaySequenceData EnterVar3;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Rebound")   
    FHazePlaySequenceData ReboundVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Rebound")   
    FHazePlaySequenceData ReboundVar1a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Rebound")   
    FHazePlaySequenceData ReboundVar2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Rebound")   
    FHazePlaySequenceData ReboundVar2a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Rebound")   
    FHazePlaySequenceData ReboundVar3;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirEnter")   
    FHazePlaySequenceData AirEnterVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirEnter")   
    FHazePlaySequenceData AirEnterVar1a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirEnter")   
    FHazePlaySequenceData AirEnterVar2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirEnter")   
    FHazePlaySequenceData AirEnterVar2a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirEnter")   
    FHazePlaySequenceData AirEnterVar3;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirRebound")   
    FHazePlaySequenceData AirReboundVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirRebound")   
    FHazePlaySequenceData AirReboundVar1a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirRebound")   
    FHazePlaySequenceData AirReboundVar2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirRebound")   
    FHazePlaySequenceData AirReboundVar2a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AirRebound")   
    FHazePlaySequenceData AirReboundVar3;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AttachPull")   
    FHazePlaySequenceData AttachVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AttachPull")   
    FHazePlaySequenceData Retract;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|AttachPull")   
    FHazePlaySequenceData OutStreched;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Throw")   
    FHazePlaySequenceData ThrowVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Throw")   
    FHazePlaySequenceData ThrowVar1a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Throw")   
    FHazePlaySequenceData ThrowVar2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Throw")   
    FHazePlaySequenceData ThrowVar2a;

    UPROPERTY(BlueprintReadOnly, Category = "Animations|LassoHold")
    FHazePlayBlendSpaceData LassoMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|LassoHold")
    FHazePlayBlendSpaceData HoldMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|UnEquipped")   
    FHazePlaySequenceData Retracted;

    UGravityWhipUserComponent GravWhipComp;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FGravityWhipAnimationData GravWhipAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FTransform TargetWorldTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FVector ObjectRelativePosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector InitialObjRelativePos;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float GravityWhipAttachAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float GravityWhipStretchAttachAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int WhipInt;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGrabbedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAirGrabbedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bAttachedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingWhip;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsReleasing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsThrowing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSlingableObject;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInThrow;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeWhipInThrow;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasGrabbedObject;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWhipGrabHadTarget;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasTurnedIntoWhipHit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ThrowStartPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromAttach;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromPull;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform ZoeHipsTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHitGloryKill;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData ActiveGloryKill;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTorHammerAttackStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTorHammerAttackEnd;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasAttachedGrab;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHolstered;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|TorHammer")   
    FHazePlaySequenceData TorHammerEnter;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|TorHammer")   
    FHazePlaySequenceData TorHammerAttack;

	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		// will be null when in editor and you compile stuff
		if(Game::GetZoe() == nullptr)
            return;

        // TODO: Get player it's attached to instead of hardcoding Zoe
        GravWhipComp = UGravityWhipUserComponent::GetOrCreate(Game::GetZoe());
        if (GravWhipComp == nullptr)
            return;

		bZoeWhipInThrow = false;

		TargetWorldTransform.Location = GravWhipComp.GrabCenterLocation;

    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{  
        if (GravWhipComp == nullptr)
            return;

        GravWhipAnimData = GravWhipComp.AnimationData;
		bIsHolstered = GravWhipComp.bIsHolstered;

		bIsReleasing = GravWhipAnimData.ReleasedThisFrame();
		bIsThrowing = GravWhipAnimData.ThrownThisFrame();

		FVector ViewPosition = Game::Zoe.ViewRotation.RotateVector(FVector(5000, 0, 0));
		ViewPosition += Game::Zoe.ViewLocation;

		//GravWhipComp.HasGrabbedActor()
		

		if (TopLevelGraphRelevantStateName == "Throw")
		{
			bInThrow = true;
		}
		else 
			bInThrow = false;
		
		// Set Whip end location
		//Print("GravWhipComp.GetNumGrabbedComponents(): " + GravWhipComp.GetNumGrabbedComponents(), 0.f); // Emils Print
		if (bInThrow)
		{
			TargetWorldTransform.Location = GetAnimVectorParam(n"WhipTargetLocation", true);
			//TargetWorldTransform.Location = ViewPosition;
		}
		else 
		{
			TargetWorldTransform.Location = GravWhipComp.GrabCenterLocation;
		}
		//Print("TargetWorldTransform.Location: " + TargetWorldTransform.Location, 0.f); // Emils Print
		// if (bGrabbedThisFrame || bInThrow)
		// 	TargetWorldTransform.Location = GetAnimVectorParam(n"WhipTargetLocation", true);
		// else if (bAirGrabbedThisFrame)
		// 	TargetWorldTransform.Location = GravWhipComp.GrabCenterLocation;
		// Print("bInThrow: " + bInThrow, 0.f); // Emils Print
			
		// Get data sent from the Player ABP
		InitialObjRelativePos = GetAnimVectorParam(n"WhipInitialTargetPos", true);
        ObjectRelativePosition = GetAnimVectorParam(n"WhipTargetPos", true);
		bSlingableObject = GetAnimBoolParam(n"WhipSlingableObject", true);	
		WhipInt = GetAnimIntParam(n"WhipInt", false);
		bIsRequestingWhip = GetAnimBoolParam(n"WhipIsRequestingWhip", true);
		bInEnter = GetAnimBoolParam(n"WhipInEnter", true);
		bZoeWhipInThrow = GetAnimBoolParam(n"ZoeWhipInThrow", true);
		bHasGrabbedObject = GetAnimBoolParam(n"WhipHasGrabbedObject", true);
		bWhipGrabHadTarget = GetAnimBoolParam(n"WhipGrabHadTarget", true);
		bHasTurnedIntoWhipHit = GetAnimBoolParam(n"HasTurnedIntoWhipHit", false);
		ThrowStartPosition = GetAnimFloatParam(n"ThrowStartPosition", false);
		bCameFromAttach = GetAnimBoolParam(n"CameFromAttach", true);
		bCameFromPull = GetAnimBoolParam(n"CameFromPull", true);

		//ThrowStartPosition /= 1.5;


		bGrabbedThisFrame = GravWhipAnimData.GrabbedThisFrame();
		bAirGrabbedThisFrame = GravWhipAnimData.AirGrabbedThisFrame();
		bAttachedThisFrame = GravWhipAnimData.GrabAttachedThisFrame();
		bHasAttachedGrab = GravWhipComp.HasActiveGrab();

		bHitGloryKill = GravWhipComp.ActiveGloryKill.IsSet();
		if (bHitGloryKill)
			ActiveGloryKill = GravWhipComp.ActiveGloryKill.Value.Sequence.WhipAnimation;
	
		ZoeHipsTransform = Game::Zoe.Mesh.GetSocketTransform(n"Hips");

        // Gravity Whip Attach Alpha
        const float TargetWhipAlpha = GetAnimFloatParam(n"GravityWhipAttachAlpha");
        if (GravityWhipAttachAlpha != TargetWhipAlpha)
            GravityWhipAttachAlpha = Math::FInterpTo(GravityWhipAttachAlpha, TargetWhipAlpha, DeltaTime, GetAnimFloatParam(n"GravityWhipAttachAlphaInterpSpeed"));

		const float TargetWhipStretchAlpha = GetAnimFloatParam(n"GravityWhipStretchAlpha");
        if (GravityWhipStretchAttachAlpha != TargetWhipStretchAlpha)
            GravityWhipStretchAttachAlpha = Math::FInterpTo(GravityWhipStretchAttachAlpha, TargetWhipStretchAlpha, DeltaTime, GetAnimFloatParam(n"GravityWhipAttachStretchAlphaSpeed"));
            
		
		// Make sure Enter and Rebound resets when button is pressed
		if (bGrabbedThisFrame || bAirGrabbedThisFrame)
		{
			ResetSyncGroup(n"ReboundSync");
			ResetSyncGroup(n"EnterSync");
		}

        #if EDITOR

		/*
		Debug::DrawDebugCoordinateSystem(Game::Zoe.Mesh.GetSocketLocation(n"Align"), Game::Zoe.Mesh.GetSocketRotation(n"Align"), 100, 3);
		Debug::DrawDebugCoordinateSystem(GravWhipComp.Whip.Mesh.GetSocketLocation(n"Align"), GravWhipComp.Whip.Mesh.GetSocketRotation(n"Align"), 100, 3);
		Print("TargetWorldTransform.Location: " + TargetWorldTransform.Location, 0.f); // Emils Print
		Print("bGrabbedThisFrame: " + bGrabbedThisFrame, 0.f); // Emils Print
		Print("bAirGrabbedThisFrame: " + bAirGrabbedThisFrame, 0.f); // Emils Print
		Print("bIsRequestingWhip: " + bIsRequestingWhip, 0.f);
		Print("bIsThrowing: " + bIsThrowing, 0.f); // Emils Print
		Print("bIsReleasing: " + bIsReleasing, 0.f); // Emils Print
		Print("bHasGrabbedObject: " + bHasGrabbedObject, 0.f);
		
			Print("WhipInt: " + WhipInt, 0.f);
			Print("bZoeWhipInThrow: " + bZoeWhipInThrow, 0.f); // Emils Print
			Print("bSlingableObject: " + bSlingableObject, 0.f);
			Print("Target?: " + GravWhipComp.IsTargetingAny(), 0.f); // Emils Print
			Print("bIsThrowing: " + bIsThrowing, 0.f); // Emils Print
			PrintToScreen(f"{WhipInt=}");
			Print("bInEnter: " + bInEnter, 0.f);
			Print("OBJ Rel Pos X: " + ObjectRelativePosition.X, 0.f);
			Print("OBJ Rel Pos Y: " + ObjectRelativePosition.Y, 0.f);
			PrintToScreenScaled("GravityWhipStretchAttachAlpha: " + GravityWhipStretchAttachAlpha, 0.f, Scale = 3.f); // Emils Print
			PrintToScreenScaled("GravityWhipAttachAlpha: " + GravityWhipAttachAlpha, 0.f, Scale = 3.f); // Emils Print
		*/
		#endif



    }

	UFUNCTION()
	float GetBlendTime() const
	{
		return 0.0;
	}

	// UFUNCTION()
	// void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	// {
	// 	InitialObjRelativePos = GetAnimVectorParam(n"WhipInitialTargetPos", false);
    //     ObjectRelativePosition = GetAnimVectorParam(n"WhipTargetPos", false);
	// 	bSlingableObject = GetAnimBoolParam(n"WhipSlingableObject", false);	
	// 	WhipInt = GetAnimIntParam(n"WhipInt", false);
	// 	bIsRequestingWhip = GetAnimBoolParam(n"WhipIsRequestingWhip", false);
	// 	bInEnter = GetAnimBoolParam(n"WhipInEnter", false);
	// 	bZoeWhipInThrow = GetAnimBoolParam(n"ZoeWhipInThrow", false);
	// 	bIsReleasing = GetAnimBoolParam(n"WhipHasReleased", false);
	// 	bHasGrabbedObject = GetAnimBoolParam(n"bHasGrabbedObject", false);
	// }

	UFUNCTION()
    void AnimNotify_UnHideBones()
    {
		if(GravWhipComp == nullptr)
			return;

		if (GravWhipComp.Whip != nullptr)
			GravWhipComp.Whip.Mesh.UnHideBoneByName(n"WhipBase");
    }
 
	
}
