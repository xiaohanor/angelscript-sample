

/**
 * A component containing the wanted camera targets for the parent components
 */
UCLASS(HideCategories = "Debug Activation Cooking Tags Collision", Meta = (DisplayName = "OptionalTargetLocation"))
class UCameraWeightedTargetOptionalComponent : UHazeCameraResponseComponent
{
	access EditAndReadOnly = protected, * (editdefaults, readonly), CameraReplace;

	UPROPERTY(Category = "Focus Targets", EditAnywhere, meta = (InlineEditConditionToggle))
    access:EditAndReadOnly bool bUseCustomLocationTargets = false;

	/** Where the camera should position itself. If no targets are provided, focus targets will be used instead */
    UPROPERTY(Category = "Focus Targets", EditAnywhere, meta = (EditCondition = "bUseCustomLocationTargets"))
    access:EditAndReadOnly TArray<FHazeCameraWeightedFocusTargetInfo> CustomLocationTargets;

	private bool bHasBegunPlay = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		bHasBegunPlay = true;
	}

	private FInstigator GetDefaultValueInstigator() const property
	{
		return FInstigator(this, n"DefaultValue");
	}

	bool HasValidTargets() const
    {
		if(!bUseCustomLocationTargets)
			return false;

        for(auto It : CustomLocationTargets)
        {
            if(It.IsValid())
                return true;
        }
        return false;
    }

	FFocusTargets GetFocusTargets(AHazePlayerCharacter Player) const
	{
		devCheck(bHasBegunPlay);
		return GetSpecificFocusTargets(Player, FCameraWeightedTargetGetterSettings());
	}

	FFocusTargets GetSpecificFocusTargets(AHazePlayerCharacter Player, FCameraWeightedTargetGetterSettings GetterSettings) const
	{
		devCheck(bHasBegunPlay);
		FFocusTargets Out;
		
		float TotalWeight = 0;
		for(auto It : CustomLocationTargets)
		{
			if(!It.IsValid())
				continue;

			// Is the other player also using this	
			AHazePlayerCharacter OtherPlayer = Player.OtherPlayer;
			if(!GetterSettings.bCanIncludeOtherUser || !IsUsedByPlayer(OtherPlayer))
				OtherPlayer = nullptr;

			if(!It.CanPlayerFocusOn(Player, OtherPlayer))
				continue;

			if(It.IsMarkedPrimary() && !GetterSettings.bIncludeMarkedPrimaryTargets)
				continue;

			if(!It.IsMarkedPrimary() && !GetterSettings.bIncludeUnMarkedTargets)
				continue;	

			FHazeCameraFinalizedWeightedFocusTargetInfo FinalData;
			FinalData.Fill(Player, It);
			
			// Targets without weights are ignored
			if(FinalData.Weight <= SMALL_NUMBER)
				continue;	

			TotalWeight += FinalData.Weight;

			#if TEST
			if(GetterSettings.bIncludeDebugInfo)
			{
				It.GetDebugInfo(FinalData.DebugInfo);
				FinalData.SetActorDebugName(Owner);		
			}
			#endif

			Out.Add(FinalData);
		}

		// If not targets are provided, we use the current user as a target
		if(TotalWeight < SMALL_NUMBER || Out.Targets.Num() == 0)
		{
			FHazeCameraFinalizedWeightedFocusTargetInfo DefaultCameraUserTarget;
			//DefaultCameraUserTarget.Component = Player.RootComponent;
			DefaultCameraUserTarget.Location = Player.GetFocusLocation();
			Out.Add(DefaultCameraUserTarget);
			return Out;
		}
		
		// Fixup the total weight
		Out.BalanceWeight(TotalWeight);
		return Out;
	}


#if EDITOR

	FFocusTargets GetEditorPreviewTargets() const
	{
		FFocusTargets Out;
		auto MainTargetComponent = UCameraWeightedTargetComponent::Get(Owner);
		if(MainTargetComponent == nullptr)
			return Out;

		if(!bUseCustomLocationTargets)
			return Out;
		
		float TotalWeight = 0;
		for(auto It : CustomLocationTargets)
		{
			if(!It.IsValid())
				continue;
		
			Out.Add(MainTargetComponent.GetEditorPreviewFocus(It));
			TotalWeight += Out.Last().Weight;
		}

		if(Out.Targets.Num() == 0)
		{
			FHazeCameraFinalizedWeightedFocusTargetInfo DefaultPreview;
			DefaultPreview.Location = Editor::EditorViewLocation;
			TotalWeight += 1;
			Out.Add(DefaultPreview);
		}

		if(TotalWeight > 0)
		{
			Out.BalanceWeight(TotalWeight);
		}

		return Out;
	}
#endif

#if TEST
	void TemporalLogDrawTargets(AHazePlayerCharacter Player)
	{
		auto User = UCameraUserComponent::Get(Player);
		auto TemporalLog = User.GetCameraTemporalLog();

		auto FocusTargets = GetFocusTargets(Player);
		for(int i = 0; i < FocusTargets.Num(); ++i)
		{
			auto Target = FocusTargets[i];
			FVector LocalOffset = Target.Rotation.UnrotateVector(Target.Location - Target.Location);
			
			const FString Category = FString(f"{i}#Target_{i + 1}: {Target.DebugActorName}");
			float DebugRadius = 100;

			TemporalLog.Value(f"{Category};Target:", Target.DebugInfo);
			TemporalLog.Value(f"{Category};Weight:", Target.Weight);
			TemporalLog.Value(f"{Category};Offset:", LocalOffset);
			TemporalLog.Sphere(f"{Category};Location:", Target.Location, DebugRadius);
			TemporalLog.Arrow(f"{Category};Find Target:", Player.ViewLocation, Target.Location);
		}
	}
#endif

}
