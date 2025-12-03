class ATundra_SlidingIceBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UTundraTreeGuardianRangedInteractionTargetableComponent RangedTreeInteractionTargetComp;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeReceivingComponent;

	UPROPERTY()
	FTutorialPrompt TutorialPrompt;

	FHazeTimeLike LifeGiveEmissiveTimelike;
	default LifeGiveEmissiveTimelike.Duration = 2;

	UPROPERTY()
	FLinearColor EmissiveColor;

	bool bBlockedGridPoint = false;
	ATundra_IcePalace_SlidingIceBlockBoard Board;
	FTundraGridPoint CurrentGridPoint;
	float PreviousAlpha = 0.0;
	bool bCurrentlyMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Board = TListedActors<ATundra_IcePalace_SlidingIceBlockBoard>().Single;
		CurrentGridPoint = Board.GetClosestGridPoint(ActorLocation);
		PreviousAlpha = LifeReceivingComponent.GetVerticalAlpha();
		
		LifeReceivingComponent.OnInteractStart.AddUFunction(this, n"OnInteractStart");
		LifeReceivingComponent.OnInteractStop.AddUFunction(this, n"OnInteractStop");

		LifeGiveEmissiveTimelike.BindUpdate(this, n"LifeGiveEmissiveUpdate");

		Mesh.SetColorParameterValueOnMaterialIndex(0, n"Tint_B_Emissive", FLinearColor::Black);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = LifeReceivingComponent.GetVerticalAlpha();
		Alpha = Math::Clamp(Alpha, 0, 1);

		if(!Math::IsNearlyEqual(PreviousAlpha, Alpha))
		{
			if(!bCurrentlyMoving)
				UTundra_IcePalace_SlidingIceBlockerEffectHandler::Trigger_OnStartMoving(this);

			bCurrentlyMoving = true;
		}
		else
		{
			if(bCurrentlyMoving)
				UTundra_IcePalace_SlidingIceBlockerEffectHandler::Trigger_OnStopMoving(this);

			bCurrentlyMoving = false;
		}

		const float Tolerance = 0.025;
		if(Math::IsNearlyEqual(Alpha, 1.0, Tolerance) && !Math::IsNearlyEqual(PreviousAlpha, 1.0, Tolerance))
			UTundra_IcePalace_SlidingIceBlockerEffectHandler::Trigger_OnFullyExtended(this);

		if(Math::IsNearlyEqual(Alpha, 0.0, Tolerance) && !Math::IsNearlyEqual(PreviousAlpha, 0.0, Tolerance))
			UTundra_IcePalace_SlidingIceBlockerEffectHandler::Trigger_OnFullyRetracted(this);

		PreviousAlpha = Alpha;

		MeshRoot.SetRelativeLocation(Math::Lerp(FVector(0,0,-500), FVector(0,0,-100), Alpha));
		HandleBlock();

		TListedActors<ATundra_SlidingIceBlock> ListedBlocks;
		bool bOverlapping = false;
		for(auto Block : ListedBlocks.Array)
		{
			if(Block.IsOverlappingGridPoint(CurrentGridPoint))
			{
				bOverlapping = true;
				break;
			}
		}

		if(bOverlapping)
			RangedTreeInteractionTargetComp.Disable(this);
		else
			RangedTreeInteractionTargetComp.Enable(this);
	}

	UFUNCTION()
	private void OnInteractStart(bool bForced)
	{
		Game::Zoe.ShowTutorialPromptWorldSpace(TutorialPrompt, this, MeshRoot);
		LifeGiveEmissiveTimelike.Play();
	}
	
	UFUNCTION()
	private void OnInteractStop(bool bForced)
	{
		Game::Zoe.RemoveTutorialPromptByInstigator(this);
		LifeGiveEmissiveTimelike.Reverse();
	}

	UFUNCTION()
	private void LifeGiveEmissiveUpdate(float CurrentValue)
	{
		FLinearColor NewColor = Math::Lerp(FLinearColor::Black, EmissiveColor, CurrentValue);
		Mesh.SetColorParameterValueOnMaterialIndex(0, n"Tint_B_Emissive", NewColor);
	}

	void HandleBlock()
	{
		//Changing this from 500 to 450 since the interpolation towards 500 is quite slow /Victor
		bool bShouldBlock = MeshRoot.RelativeLocation.Z > -450;

		if(bShouldBlock != bBlockedGridPoint)
		{
			if(bShouldBlock)
			{
				Board.AddGridPointBlocker(CurrentGridPoint);
				bBlockedGridPoint = true;
			}
			else
			{
				Board.RemoveGridPointBlocker(CurrentGridPoint);
				bBlockedGridPoint = false;
			}
		}
	}
};