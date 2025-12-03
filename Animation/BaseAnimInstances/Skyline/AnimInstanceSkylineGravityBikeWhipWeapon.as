class UAnimInstanceGravityBikeWhipWeapon : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly, Category = "Animations|GrabRebound")   
    FHazePlayBlendSpaceData GrabReboundLeftBS;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|GrabRebound")   
    FHazePlayBlendSpaceData GrabReboundRightBS;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|GrabRebound")   
    FHazePlaySequenceData LassoRetracted;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|GrabRebound")   
    FHazePlayBlendSpaceData ReleaseBS;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|GrabRebound")   
    FHazePlaySequenceData EnterVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|GrabRebound")   
    FHazePlaySequenceData EnterVar1a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|GrabRebound")   
    FHazePlaySequenceData EnterVar2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Rebound")   
    FHazePlaySequenceData ReboundVar1;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Rebound")   
    FHazePlaySequenceData ReboundVar1a;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Rebound")   
    FHazePlaySequenceData ReboundVar2;

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

    UPROPERTY(BlueprintReadOnly, Category = "Animations|LassoHold")
    FHazePlayBlendSpaceData LassoMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|LassoHold")
    FHazePlayBlendSpaceData HoldMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|UnEquipped")   
    FHazePlaySequenceData Retracted;

    UGravityBikeWhipComponent WhipComp;
	
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
	bool bIsHolstered;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EGravityBikeWhipState WhipState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bHasGravityWhip;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsWhipping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D WhipInputDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D WhipReboundDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrabbedObjectLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasTarget;

	// In screen space, what direction is the item we want to grab in?
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D WhipTargetGrabDirection;
	
	// In screen space, what direction is the main target we will throw a grabbed item at?
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D WhipTargetReleaseDirection;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int WhipInt;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGrabbedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAirGrabbedThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingWhip;



	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsActive;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartGrab;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPull;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLasso;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bThrowRebound;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bThrow;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		// will be null when in editor and you compile stuff
		if(Game::GetZoe() == nullptr)
            return;

        // TODO: Get player it's attached to instead of hardcoding Zoe
        WhipComp = UGravityBikeWhipComponent::GetOrCreate(GravityBikeWhip::GetPlayer());
        if (WhipComp == nullptr)
            return;

		bIsHolstered = WhipComp.bIsHolstered;

		if(WhipComp.HasGrabbedAnything())
			TargetWorldTransform.Location = WhipComp.GetMainGrabbed().WorldLocation;
		else
			TargetWorldTransform.Location = Game::Zoe.Mesh.GetSocketLocation(n"Align");

		UpdateWhipAnimData();
		
		if (WhipTargetGrabDirection.X < 0.0)
			bIsGrabbedObjectLeft = true;
		else
			bIsGrabbedObjectLeft = false;
    }

	UGravityBikeWhipThrowTargetComponent lastthr;

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{  
        if (WhipComp == nullptr)
            return;

		UpdateWhipAnimData();

        //GravWhipAnimData = WhipComp.AnimationData;

		bHasGravityWhip = WhipComp != nullptr;

		WhipState = WhipComp.GetWhipState();
		

		bIsActive = false;
		bStartGrab = false;
		bPull = false;
		bLasso = false;
		bThrowRebound = false;
		bThrow = false;

		switch(WhipComp.GetWhipState())
		{
			case EGravityBikeWhipState::None:
				break;

			case EGravityBikeWhipState::StartGrab:
				bStartGrab = true;
				bIsActive = true;
				break;

			case EGravityBikeWhipState::Pull:
				bPull = true;
				bIsActive = true;
				break;

			case EGravityBikeWhipState::Lasso:
				bLasso = true;
				bIsActive = true;
				break;

			case EGravityBikeWhipState::ThrowRebound:
				bThrowRebound = true;
				bIsActive = true;
				break;

			case EGravityBikeWhipState::Throw:
				bThrow = true;
				bIsActive = true;
				break;

			default:
				check(false);
				break;

			
		}
		
		if(WhipComp.HasGrabbedAnything())
		{
			if (WhipComp.GetThrowTarget() != nullptr)
				lastthr = WhipComp.GetThrowTarget();
			TargetWorldTransform.Location = WhipComp.GetMainGrabbed().WorldLocation;
			
		}
		else if (lastthr != nullptr)
		{
			TargetWorldTransform.Location = Math::VInterpTo(TargetWorldTransform.Location, lastthr.WorldLocation, DeltaTime, 5.0);
		}
			
		// Get data sent from the Player ABP
		InitialObjRelativePos = GetAnimVectorParam(n"WhipInitialTargetPos", true);
        ObjectRelativePosition = GetAnimVectorParam(n"WhipTargetPos", true);
		WhipInt = GetAnimIntParam(n"WhipInt", false);
		bIsRequestingWhip = GetAnimBoolParam(n"WhipIsRequestingWhip", true);

		bIsGrabbedObjectLeft = GetAnimBoolParam(n"BikeWhipGrabbedObjectLeft");

		WhipReboundDirection = GetAnimVector2DParam(n"BikeWhipReboundDirection");


		bGrabbedThisFrame = GravWhipAnimData.GrabbedThisFrame();
		bAirGrabbedThisFrame = GravWhipAnimData.AirGrabbedThisFrame();

        // Gravity Whip Attach Alpha
        const float TargetWhipAlpha = GetAnimFloatParam(n"GravityWhipAttachAlpha");
        if (GravityWhipAttachAlpha != TargetWhipAlpha)
            GravityWhipAttachAlpha = Math::FInterpTo(GravityWhipAttachAlpha, TargetWhipAlpha, DeltaTime, GetAnimFloatParam(n"GravityWhipAttachAlphaInterpSpeed"));

		const float TargetWhipStretchAlpha = GetAnimFloatParam(n"GravityWhipStretchAlpha");
        if (GravityWhipStretchAttachAlpha != TargetWhipStretchAlpha)
            GravityWhipStretchAttachAlpha = Math::FInterpTo(GravityWhipStretchAttachAlpha, TargetWhipStretchAlpha, DeltaTime, GetAnimFloatParam(n"GravityWhipAttachStretchAlphaSpeed"));

		//WhipComp.ThrownTargets[0].WorldLocation;

        #if EDITOR	
			/*
			Debug::DrawDebugCoordinateSystem(TargetWorldTransform.Location, TargetWorldTransform.Rotation.Rotator(), 100, 10);
		Debug::DrawDebugCoordinateSystem(WhipComp.WhipActor.Mesh.GetSocketLocation(n"Root"), WhipComp.WhipActor.Mesh.GetSocketRotation(n"Root"), 50, 10);
		Print("WhipComp.HasGrabbedAnything(): " + WhipComp.HasGrabbedAnything(), 0.f);
		Debug::DrawDebugCoordinateSystem(Game::Zoe.Mesh.GetSocketLocation(n"RightAttach"), Game::Zoe.Mesh.GetSocketRotation(n"RightAttach"), 100, 3);
		Print("WhipReboundDirection: " + WhipReboundDirection, 0.f); // Emils Print
			Debug::DrawDebugCoordinateSystem(Game::Zoe.Mesh.GetSocketLocation(n"Align"), Game::Zoe.Mesh.GetSocketRotation(n"Align"), 50, 3);
        Print("TargetWhipAlpha: " + TargetWhipAlpha, 0.f);
		Print("bStartGrab: " + bStartGrab, 0.f);
		Print("bIsGrabbedObjectLeft: " + bIsGrabbedObjectLeft, 0.f);
				Print("bLasso: " + bLasso, 0.f);
			Debug::DrawDebugSphere(OwningComponent.GetSocketLocation(n"Root"), 20); 
			Print("WhipState: " + WhipState, 0.f); // Emils Print
			Print("TargetWorldTransformLocation: " + TargetWorldTransform.Location, 0.f); // Emils Print
			Debug::DrawDebugCoordinateSystem(TargetWorldTransform.Location, TargetWorldTransform.Rotator(), 1000, 30);
			Print("bIsRequestingWhip: " + bIsRequestingWhip, 0.f);
			Print("bGrabbedThisFrame: " + bGrabbedThisFrame, 0.f); // Emils Print
			Print("bIsThrowing: " + bIsThrowing, 0.f); // Emils Print
			Print("bAirGrabbedThisFrame: " + bAirGrabbedThisFrame, 0.f); // Emils Print
			Print("bZoeWhipInThrow: " + bZoeWhipInThrow, 0.f); // Emils Print
			Print("bSlingableObject: " + bSlingableObject, 0.f);
			Print("Target?: " + WhipComp.IsTargetingAny(), 0.f); // Emils Print
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
	private void UpdateWhipAnimData()
	{
		if(!bHasGravityWhip)
			return;

		bIsWhipping = WhipComp.GetWhipState() != EGravityBikeWhipState::None;
		WhipState = WhipComp.GetWhipState();
		WhipInputDirection = WhipComp.GetInputDirection();

		WhipTargetGrabDirection = WhipComp.GetMainGrabTargetDirection();
		bHasTarget = WhipComp.HasThrowTarget();
		//WhipReboundDirection = WhipTargetGrabDirection * 2.0;

		if(bHasTarget)
			WhipTargetReleaseDirection = WhipComp.GetPlayerToThrowTargetVectorUV();
	}
}
