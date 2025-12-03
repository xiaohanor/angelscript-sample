class UAnimInstanceGravityWhipWeaponGloryKillHit : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly, Category = "Animations")   
    FHazePlaySequenceData TripSlam;


    UGravityWhipUserComponent WhipComp;
	
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

	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		// will be null when in editor and you compile stuff
		if(Game::GetZoe() == nullptr)
            return;

        // TODO: Get player it's attached to instead of hardcoding Zoe
        WhipComp = UGravityWhipUserComponent::GetOrCreate(Game::GetZoe());
        if (WhipComp == nullptr)
            return;

		TargetWorldTransform.Location = WhipComp.GrabCenterLocation;

    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{  
        if (WhipComp == nullptr)
            return;

        GravWhipAnimData = WhipComp.AnimationData;


		FVector ViewPosition = Game::Zoe.ViewRotation.RotateVector(FVector(5000, 0, 0));
		ViewPosition += Game::Zoe.ViewLocation;

		//WhipComp.HasGrabbedActor()
		
		
		TargetWorldTransform.Location = GetAnimVectorParam(n"WhipTargetLocation", true);
		
		
        // Gravity Whip Attach Alpha
        const float TargetWhipAlpha = GetAnimFloatParam(n"GravityWhipAttachAlpha");
        if (GravityWhipAttachAlpha != TargetWhipAlpha)
            GravityWhipAttachAlpha = Math::FInterpTo(GravityWhipAttachAlpha, TargetWhipAlpha, DeltaTime, GetAnimFloatParam(n"GravityWhipAttachAlphaInterpSpeed"));

		const float TargetWhipStretchAlpha = GetAnimFloatParam(n"GravityWhipStretchAlpha");
        if (GravityWhipStretchAttachAlpha != TargetWhipStretchAlpha)
            GravityWhipStretchAttachAlpha = Math::FInterpTo(GravityWhipStretchAttachAlpha, TargetWhipStretchAlpha, DeltaTime, GetAnimFloatParam(n"GravityWhipAttachStretchAlphaSpeed"));
        

        #if EDITOR

		/*
		Debug::DrawDebugCoordinateSystem(Game::Zoe.Mesh.GetSocketLocation(n"Align"), Game::Zoe.Mesh.GetSocketRotation(n"Align"), 100, 3);
		Debug::DrawDebugCoordinateSystem(WhipComp.Whip.Mesh.GetSocketLocation(n"Align"), WhipComp.Whip.Mesh.GetSocketRotation(n"Align"), 100, 3);
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
		if(WhipComp == nullptr)
			return;

		if (WhipComp.Whip != nullptr)
			WhipComp.Whip.Mesh.UnHideBoneByName(n"WhipBase");
    }
 
	
}
