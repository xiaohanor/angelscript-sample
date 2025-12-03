// class UAnimNotifySetGravityWhipAttachAlpha : UAnimNotifyState
// {
// 	UPROPERTY(EditAnywhere)
// 	const float Value = 1;

// 	UPROPERTY(EditAnywhere)
// 	const float InterpSpeedIn = 20;

// 	UPROPERTY(EditAnywhere)
// 	const float InterpSpeedOut = 20;

// #if EDITOR
// 	default NotifyColor = FColor::Magenta;
// #endif

// 	UFUNCTION(BlueprintOverride)
// 	FString GetNotifyName() const
// 	{
// 		return "GravityWhipAttachAlpha";
// 	}
	
// 	UFUNCTION(BlueprintOverride)
// 	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
// 	{
// 		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
// 		if (HazeSkelMeshComp != nullptr) {
// 			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachAlpha", Value);
// 			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachAlphaInterpSpeed", InterpSpeedIn);
// 		}

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
// 	{
// 		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
// 		if (HazeSkelMeshComp != nullptr) {
// 			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachAlpha", 0);
// 			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachAlphaInterpSpeed", InterpSpeedOut);
// 		}

// 		return true;
// 	}
	
// }

// class UAnimNotifySetGravityWhipStretchAlpha : UAnimNotifyState
// {
// 	UPROPERTY(EditAnywhere)
// 	const float Value = 1;

// 	UPROPERTY(EditAnywhere)
// 	const float InterpSpeedIn = 20;

// 	UPROPERTY(EditAnywhere)
// 	const float InterpSpeedOut = 20;

// #if EDITOR
// 	default NotifyColor = FColor::Orange;
// #endif

// 	UFUNCTION(BlueprintOverride)
// 	FString GetNotifyName() const
// 	{
// 		return "GravityWhipStretchAlpha";
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
// 	{
// 		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
// 		if (HazeSkelMeshComp != nullptr) {
// 			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipStretchAlpha", Value);
// 			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachStretchAlphaSpeed", InterpSpeedIn);
// 		}

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
// 	{
// 		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
// 		if (HazeSkelMeshComp != nullptr) {
// 			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipStretchAlpha", 0);
// 			HazeSkelMeshComp.SetAnimFloatParam(n"GravityWhipAttachStretchAlphaSpeed", InterpSpeedOut);
// 		}

// 		return true;
// 	}

// }



class UAnimInstanceGrappleRope : UHazeAnimInstanceBase
{

	AGrappleHookActorV2 GrappleRope;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Throw")   
    FHazePlaySequenceData ThrowInAirVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Pull")   
    FHazePlaySequenceData PullToPointInAirVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|UnEquipped")   
    FHazePlaySequenceData Retracted;

   	UGravityWhipUserComponent GravWhipComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FGravityWhipAnimationData GravWhipAnimData;
	
	UPROPERTY()
	UPlayerGrappleComponent GrappleComp;

	UPROPERTY()
	EHazeGrappleHookHeightMomentumAnimationType HeightDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerGrappleAnimData GrappleAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform GrappleWorldPos;

	

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
	float ThrowStartPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromAttach;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromPull;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator ZoeRightHandRotation;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		//  if (HazeOwningActor == nullptr)
        //     return;
		
		GrappleRope = Cast<AGrappleHookActorV2>(HazeOwningActor);
		if(GrappleRope == nullptr)
			GrappleRope = Cast<AGrappleHookActorV2>(HazeOwningActor.AttachParentActor);

		// {
		// 	Player = Cast<AGravityWhipActor>(HazeOwningActor.AttachParentActor);
		// }
		// MoveComp = UHazeMovementComponent::Get(Player);		

	}

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		// will be null when in editor and you compile stuff
		// if(Game::GetZoe() == nullptr)
        //     return;

		if (GrappleRope == nullptr)
			return;

		if(GrappleRope.Player != nullptr)
		{
			GrappleComp = UPlayerGrappleComponent::Get(GrappleRope.Player);
		}

        // TODO: Get player it's attached to instead of hardcoding Zoe
        // GravWhipComp = UGravityWhipUserComponent::GetOrCreate(Game::GetZoe());
        // if (GravWhipComp == nullptr)
        //     return;

		// bZoeWhipInThrow = false;

		// TargetWorldTransform.Location = GravWhipComp.GrabCenterLocation;

    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{  
        if (GrappleComp != nullptr)
        {
       		GrappleAnimData = GrappleComp.AnimData;
			if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::Inactive)
			{
				GrappleWorldPos.Location = GrappleComp.Data.CurrentGrapplePoint.WorldLocation;

			}
		}

		// bIsReleasing = GravWhipAnimData.ReleasedThisFrame();
		// bIsThrowing = GravWhipAnimData.ThrownThisFrame();

		// if (TopLevelGraphRelevantStateName == "Throw")
		// {
		// 	bInThrow = true;
		// }
		// else 
		// 	bInThrow = false;
		


		// // Set Whip end location
		// //Print("GravWhipComp.GetNumGrabbedComponents(): " + GravWhipComp.GetNumGrabbedComponents(), 0.f); // Emils Print
		// if (bInThrow)
		// {
		// 	TargetWorldTransform.Location = GetAnimVectorParam(n"WhipTargetLocation", true);
		// }
		// else 
		// {
		// 	TargetWorldTransform.Location = GravWhipComp.GrabCenterLocation;
		// }
		// //Print("TargetWorldTransform.Location: " + TargetWorldTransform.Location, 0.f); // Emils Print
		// // if (bGrabbedThisFrame || bInThrow)
		// // 	TargetWorldTransform.Location = GetAnimVectorParam(n"WhipTargetLocation", true);
		// // else if (bAirGrabbedThisFrame)
		// // 	TargetWorldTransform.Location = GravWhipComp.GrabCenterLocation;
			
		// // Get data sent from the Player ABP
		// InitialObjRelativePos = GetAnimVectorParam(n"WhipInitialTargetPos", true);
        // ObjectRelativePosition = GetAnimVectorParam(n"WhipTargetPos", true);
		// bSlingableObject = GetAnimBoolParam(n"WhipSlingableObject", true);	
		// WhipInt = GetAnimIntParam(n"WhipInt", false);
		// bIsRequestingWhip = GetAnimBoolParam(n"WhipIsRequestingWhip", true);
		// bInEnter = GetAnimBoolParam(n"WhipInEnter", true);
		// bZoeWhipInThrow = GetAnimBoolParam(n"ZoeWhipInThrow", true);
		// bHasGrabbedObject = GetAnimBoolParam(n"WhipHasGrabbedObject", true);
		// ThrowStartPosition = GetAnimFloatParam(n"ThrowStartPosition", false);
		// bCameFromAttach = GetAnimBoolParam(n"CameFromAttach", true);
		// bCameFromPull = GetAnimBoolParam(n"CameFromPull", true);

		// //ThrowStartPosition /= 1.5;


		// bGrabbedThisFrame = GravWhipAnimData.GrabbedThisFrame();
		// bAirGrabbedThisFrame = GravWhipAnimData.AirGrabbedThisFrame();
		// bAttachedThisFrame = GravWhipAnimData.GrabAttachedThisFrame();

	
		// ZoeRightHandRotation = Game::Zoe.Mesh.GetSocketRotation(n"RightHand");

        // Gravity Whip Attach Alpha
        const float TargetWhipAlpha = GetAnimFloatParam(n"GrappleHookAttachAlpha");
        if (GravityWhipAttachAlpha != TargetWhipAlpha)
            GravityWhipAttachAlpha = Math::FInterpTo(GravityWhipAttachAlpha, TargetWhipAlpha, DeltaTime, GetAnimFloatParam(n"GravityWhipAttachAlphaInterpSpeed"));



		const float TargetWhipStretchAlpha = GetAnimFloatParam(n"GrappleHookStretchAlpha");
        if (GravityWhipStretchAttachAlpha != TargetWhipStretchAlpha)
            GravityWhipStretchAttachAlpha = Math::FInterpTo(GravityWhipStretchAttachAlpha, TargetWhipStretchAlpha, DeltaTime, GetAnimFloatParam(n"GravityWhipAttachStretchAlphaSpeed"));


		
		// // Make sure Enter and Rebound resets when button is pressed
		// if (bGrabbedThisFrame || bAirGrabbedThisFrame)
		// {
		// 	ResetSyncGroup(n"ReboundSync");
		// 	ResetSyncGroup(n"EnterSync");
		// }

        #if EDITOR	
		
		/*
		Print("TargetWorldTransform.Location: " + TargetWorldTransform.Location, 0.f); // Emils Print
		Debug::DrawDebugCoordinateSystem(GravWhipComp.Whip.Mesh.GetSocketLocation(n"Align"), GravWhipComp.Whip.Mesh.GetSocketRotation(n"Align"), 100, 3);
		Print("bGrabbedThisFrame: " + bGrabbedThisFrame, 0.f); // Emils Print
		Print("bAirGrabbedThisFrame: " + bAirGrabbedThisFrame, 0.f); // Emils Print
		Print("bIsRequestingWhip: " + bIsRequestingWhip, 0.f);
		Debug::DrawDebugCoordinateSystem(Game::Zoe.Mesh.GetSocketLocation(n"RightAttach"), Game::Zoe.Mesh.GetSocketRotation(n"RightAttach"), 100, 3);
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
