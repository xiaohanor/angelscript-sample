/**
 * A component containing the focus targets for the parent components
 */
 UCLASS(HideCategories = "Debug Activation Cooking Tags Collision")
class UCameraWeightedTargetComponent : UHazeCameraResponseComponent
{
	access EditAndReadOnly = protected, * (editdefaults, readonly), CameraReplace;
	

    // The targets we want to keep in view, if possible due to fov and distance constraints
    UPROPERTY(Category = "Focus Targets", EditAnywhere, DisplayName = "Focus Targets")
    access:EditAndReadOnly TArray<FHazeCameraWeightedFocusTargetInfo> Targets;

	// If no targets are added, this is the target type that will be used
	UPROPERTY(Category = "Focus Targets", EditConst, VisibleAnywhere, DisplayName = "Focus Targets", meta = (EditCondition="!bHasValidTargetsInternal", EditConditionHides))
	ECameraWeightedTargetEmptyInitType EmptyTargetDefaultType = ECameraWeightedTargetEmptyInitType::DefaultToUser;

	// Apply to override focus settings for the players when this is active
	UPROPERTY(Category = "Focus Targets", EditAnywhere, DisplayName = "Player Focus Settings", Meta=(ShowOnlyInnerProperties))
	access:EditAndReadOnly UPlayerFocusTargetSettings PlayerFocusSettingsOverride;

	private TArray<FInternalInstigatedCameraWeightedRuntimeTarget> RuntimeTargets;
	private TArray<FInternalInstigatedCameraWeightedRuntimeTarget> DefaultTargets;

	private bool bHasBegunPlay = false;
	private FHazeCameraRuntimeVector RuntimeViewOffset;
	private FHazeCameraRuntimeVector RuntimeWorldOffset;

	UPROPERTY()
	private bool bHasValidTargetsInternal = false;

#if EDITOR
	UPROPERTY(EditAnywhere, EditFixedSize, Category = "DebugTransforms")
	TMap<FName, FTransform> EditorDebugPlayerTargetTransforms;
	default EditorDebugPlayerTargetTransforms.Add(n"Player", FTransform::Identity);
	default EditorDebugPlayerTargetTransforms.Add(n"OtherPlayer", FTransform::Identity);
	default EditorDebugPlayerTargetTransforms.Add(n"Mio", FTransform::Identity);
	default EditorDebugPlayerTargetTransforms.Add(n"Zoe", FTransform::Identity);
	default EditorDebugPlayerTargetTransforms.Add(n"Custom", FTransform::Identity);
	UHazeSplineComponent EditorDebugSpline;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		bHasValidTargetsInternal = false;
		for(auto It : Targets)
		{
			if(It.IsValid())
			{
				bHasValidTargetsInternal = true;
				break;
			}
		}	 
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		bHasBegunPlay = true;

		if(Targets.Num() > 0)
		{
			// Convert all the targets into valid runtime targets
			for(auto It : Targets)
			{
				AddFocusTargetInternal(It, DefaultValueInstigator, EHazeSelectPlayer::Both);
			}
		}
		else
		{	
			ApplyDefaults(DefaultTargets);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User)
	{
		if(PlayerFocusSettingsOverride == nullptr)
			return;

		auto Player = User.GetPlayerOwner();
		if(Player == nullptr)
			return;

		Player.ApplySettings(PlayerFocusSettingsOverride, this, EHazeSettingsPriority::Override);
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraDeactivated(UHazeCameraUserComponent User)
	{
		if(PlayerFocusSettingsOverride == nullptr)
			return;

		auto Player = User.GetPlayerOwner();
		if(Player == nullptr)
			return;

		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	protected void OnCameraUpdateForUser(const UHazeCameraUserComponent HazeUser, float DeltaTime)
	{
		RuntimeViewOffset.Update(HazeUser, DeltaTime);
		RuntimeWorldOffset.Update(HazeUser, DeltaTime);	
	}

	UFUNCTION(BlueprintOverride)
	protected void OnCameraSnapForUser(const UHazeCameraUserComponent HazeUser)
	{
		RuntimeViewOffset.Snap(HazeUser);
		RuntimeWorldOffset.Snap(HazeUser);
	}

	private FInstigator GetDefaultValueInstigator() const property
	{
		return FInstigator(this, n"DefaultValue");
	}

	private void ApplyDefaults(TArray<FInternalInstigatedCameraWeightedRuntimeTarget>& OutDefaults) const
	{
		if(EmptyTargetDefaultType == ECameraWeightedTargetEmptyInitType::DefaultToUser)
		{
			FInternalInstigatedCameraWeightedRuntimeTarget User;
			User.Instigator = DefaultValueInstigator;
			User.Target.SetFocusToUser();
			OutDefaults.Add(User);
		}
		else if(EmptyTargetDefaultType == ECameraWeightedTargetEmptyInitType::DefaultToBothUsers)
		{
			FInternalInstigatedCameraWeightedRuntimeTarget User;
			User.Instigator = DefaultValueInstigator;
			User.Target.SetFocusToUser();
			OutDefaults.Add(User);
			
			FInternalInstigatedCameraWeightedRuntimeTarget OtherUser;
			OtherUser.Instigator = DefaultValueInstigator;
			OtherUser.Target.SetFocusToOtherUser();
			OutDefaults.Add(OtherUser);
		}
		else if(EmptyTargetDefaultType == ECameraWeightedTargetEmptyInitType::DefaultToBothPlayers)
		{
			FInternalInstigatedCameraWeightedRuntimeTarget Mio;
			Mio.Instigator = DefaultValueInstigator;
			Mio.Target.SetFocusToPlayerMio();
			OutDefaults.Add(Mio);
			
			FInternalInstigatedCameraWeightedRuntimeTarget Zoe;
			Zoe.Instigator = DefaultValueInstigator;
			Zoe.Target.SetFocusToPlayerZoe();
			OutDefaults.Add(Zoe);
		}
	}

	// DEPRECATED
	UFUNCTION(Meta=(DeprecatedFunction, DeprecationMessage="Just use the 'AddFocusTarget'"))
	protected void BP_AddFocusTarget(FHazeCameraWeightedFocusTargetInfo FocusTarget, FInstigator Instigator)
	{
		devError("BP_AddFocusTarget is deprecated. Just use the 'AddFocusTarget'");
		AddFocusTarget(FocusTarget, Instigator);
	}

	UFUNCTION()
	void AddFocusTarget(FHazeCameraWeightedFocusTargetInfo FocusTarget, FInstigator Instigator, EHazeSelectPlayer UsedByPlayer = EHazeSelectPlayer::Both)
	{
		// You can't add a target before begin play has triggered.
		// Use the default params instead
		if(!devEnsure(bHasBegunPlay, "You can't add a target before begin play has triggered"))
			return;

		#if EDITOR
		{
			for(auto It : RuntimeTargets)
			{
				if(It.Instigator != Instigator)
					continue;

				if(!It.Target.Equals(FocusTarget))
					continue;
				
				FString DebugInfo;
				FocusTarget.GetDebugInfo(DebugInfo);
				devError(f"AddFocusTarget {DebugInfo} has already been called by {Instigator}");
			}
		}
		#endif

		AddFocusTargetInternal(FocusTarget, Instigator, UsedByPlayer);
	}

	// DEPRECATED
	UFUNCTION(Meta=(DeprecatedFunction, DeprecationMessage="Just use the 'RemoveAllAddFocusTargetsByInstigator'"))
	protected void BP_RemoveAllAddFocusTargetsByInstigator(FInstigator Instigator)
	{
		devError("BP_RemoveAllAddFocusTargetsByInstigator is deprecated. Just use the 'RemoveAllAddFocusTargetsByInstigator'");
		RemoveAllAddFocusTargetsByInstigator(Instigator);
	}

	// This will remove all the focus targets that has been added using the 'AddFocusTarget' function
	UFUNCTION()
	void RemoveAllAddFocusTargetsByInstigator(FInstigator Instigator)
	{
		// You can't remove a target before begin play has triggered.
		// Use the default params instead
		if(!devEnsure(bHasBegunPlay, "You can't remove a target before begin play has triggered"))
			return;

		#if EDITOR
		bool bFound = false;
		for(int i = RuntimeTargets.Num() - 1; i >= 0; --i)
		{
			if(RuntimeTargets[i].Instigator == Instigator)
			{
				bFound = true;
				break;
			}
		}

		if(!devEnsure(bFound, f"No Focus targets was added using {Instigator} to {this} ({Owner})"))
			return;

		#endif

		RemoveFocusTargetInternal(Instigator);
	}

	// Add a view offset to all the view targets default view offset.
	UFUNCTION(Category = "Settings", Meta = (AdvancedDisplay = "Priority"))
	void ApplyAdditiveViewOffset(AHazePlayerCharacter Player, FVector Offset, FInstigator Instigator, EHazeCameraPriority Priority = EHazeCameraPriority::Minimum)
	{
		if(Player == nullptr)
			return;

		auto User = UHazeCameraUserComponent::Get(Player);
		RuntimeViewOffset.Apply(User, Offset, Instigator, Priority = Priority);
	}
	
	UFUNCTION(Category = "Settings")
	void ClearAdditiveViewOffset(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto User = UHazeCameraUserComponent::Get(Player);
		RuntimeViewOffset.Clear(User, Instigator, 0);
	}

	// Add a offset to all the view targets default offset.
	UFUNCTION(Category = "Settings", Meta = (AdvancedDisplay = "Priority"))
	void ApplyWorldOffset(AHazePlayerCharacter Player, FVector Offset, FInstigator Instigator, EHazeCameraPriority Priority = EHazeCameraPriority::Minimum)
	{
		if(Player == nullptr)
			return;

		auto User = UHazeCameraUserComponent::Get(Player);
		RuntimeWorldOffset.Apply(User, Offset, Instigator, Priority = Priority);
	}
	
	UFUNCTION(Category = "Settings")
	void ClearWorldOffset(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto User = UHazeCameraUserComponent::Get(Player);
		RuntimeWorldOffset.Clear(User, Instigator, 0);
	}

	private void AddFocusTargetInternal(FHazeCameraWeightedFocusTargetInfo FocusTarget, FInstigator Instigator, EHazeSelectPlayer UsedByPlayer)
	{
		FInternalInstigatedCameraWeightedRuntimeTarget NewIndex;
		NewIndex.Target = FocusTarget;
		NewIndex.Instigator = Instigator;
		NewIndex.UsedByPlayer = UsedByPlayer;
		RuntimeTargets.Add(NewIndex);
	}

	private void RemoveFocusTargetInternal(FInstigator Instigator)
	{
		for(int i = RuntimeTargets.Num() - 1; i >= 0; --i)
		{
			if(RuntimeTargets[i].Instigator != Instigator)
				continue;

			RuntimeTargets.RemoveAtSwap(i);
		}
	}

	FFocusTargets GetFocusTargets(AHazePlayerCharacter Player) const
	{
		check(bHasBegunPlay);
		return GetSpecificFocusTargets(Player, FCameraWeightedTargetGetterSettings());
	}

	FFocusTargets GetPrimaryTargetsOnly(AHazePlayerCharacter Player) const
	{
		check(bHasBegunPlay);
		FCameraWeightedTargetGetterSettings Getter;
		Getter.bIncludeMarkedPrimaryTargets = true;
		Getter.bIncludeUnMarkedTargets = false;
		return GetSpecificFocusTargets(Player, Getter);
	}

	FFocusTargets GetSpecificFocusTargets(AHazePlayerCharacter Player, FCameraWeightedTargetGetterSettings GetterSettings) const
	{
		check(bHasBegunPlay);
		FFocusTargets Out;
		
		// If we don't have any active runtime targets
		// we use the default targets
		if(RuntimeTargets.Num() > 0)
			GetSpecificFocusTargetsInternal(Player, GetterSettings, RuntimeTargets, Out);
		
		// If we had runtime targets, but none of them were valid for this player, still use the default targets
		if (Out.Targets.Num() == 0)
			GetSpecificFocusTargetsInternal(Player, GetterSettings, DefaultTargets, Out);

		return Out;
	}

	private void GetSpecificFocusTargetsInternal(
		AHazePlayerCharacter Player, 
		FCameraWeightedTargetGetterSettings GetterSettings, 
		TArray<FInternalInstigatedCameraWeightedRuntimeTarget> FromTargets,
		FFocusTargets& Out) const
	{
		// Calculate the runtime view offset
		auto User = UHazeCameraUserComponent::Get(Player);
		
		// Extract the runtime settings
		FVector CustomViewOffset = FVector::ZeroVector;
		FVector CustomWorldOffset = FVector::ZeroVector;
		if(GetterSettings.bIncludeRuntimeSettings)
		{
			RuntimeViewOffset.GetValue(User, CustomViewOffset, false);
			CustomViewOffset = Player.GetViewRotation().RotateVector(CustomViewOffset);	

			RuntimeWorldOffset.GetValue(User, CustomWorldOffset, false);
		}

		float TotalWeight = 0;		
		for(auto It : FromTargets)
		{
			if(!It.Target.IsValid())
				continue;

			// Check if focus target is used by player
			if (!Player.IsSelectedBy(It.UsedByPlayer))
				continue;

			// Is the other player also using this
			AHazePlayerCharacter OtherPlayer = Player.OtherPlayer;
			if(!GetterSettings.bCanIncludeOtherUser || !IsUsedByPlayer(OtherPlayer))
				OtherPlayer = nullptr;

			if(!It.Target.CanPlayerFocusOn(Player, OtherPlayer))
				continue;

			if(It.Target.IsMarkedPrimary() && !GetterSettings.bIncludeMarkedPrimaryTargets)
				continue;

			if(!It.Target.IsMarkedPrimary() && !GetterSettings.bIncludeUnMarkedTargets)
				continue;

			FHazeCameraFinalizedWeightedFocusTargetInfo FinalData;
			FinalData.Fill(Player, It.Target);

			// Targets without weights are ignored
			if(FinalData.Weight <= SMALL_NUMBER)
				continue;	

			TotalWeight += FinalData.Weight;

			// Add runtime settings
			{
				FinalData.Location += CustomViewOffset;
				FinalData.Location += CustomWorldOffset;
			}
			
			#if TEST
			if(GetterSettings.bIncludeDebugInfo)
			{
				It.Target.GetDebugInfo(FinalData.DebugInfo);
				FinalData.SetActorDebugName(Owner);	
			}
			#endif
			
			Out.Add(FinalData);
		}

		if(TotalWeight > 0)
		{
			// Fixup the total weight
			for(auto& It : Out.Targets)
			{
				It.Weight /= TotalWeight;
			}
		}
	}

#if EDITOR

	FFocusTargets GetEditorPreviewTargets(bool bIncludePrimary = true) const
	{
		FFocusTargets Out;
		float TotalWeight = 0;	
		for(auto It : Targets)
		{
			if(!It.IsValid())
				continue;

			if(It.IsMarkedPrimary() && !bIncludePrimary)
				continue;
		
			Out.Add(GetEditorPreviewFocus(It));
			TotalWeight += Out.Last().Weight;
		}

		if(TotalWeight > 0)
		{
			Out.BalanceWeight(TotalWeight);
			return Out;
		}
		
		// If we don't have any targets, we use the default types
		TArray<FInternalInstigatedCameraWeightedRuntimeTarget> EditorDefaults;
		ApplyDefaults(EditorDefaults);

		for(auto It : EditorDefaults)
		{		
			Out.Add(GetEditorPreviewFocus(It.Target));
			TotalWeight += Out.Last().Weight;
		}	

		if(TotalWeight > 0)
		{
			Out.BalanceWeight(TotalWeight);
		}

		return Out;
	}

	FFocusTargets GetEditorPreviewPrimaryTargets() const
	{
		FFocusTargets Out;
		float TotalWeight = 0;
		for(auto It : Targets)
		{
			if(!It.IsValid())
				continue;

			if(!It.IsMarkedPrimary())
				continue;
		
			Out.Add(GetEditorPreviewFocus(It));
			TotalWeight += Out.Last().Weight;
		}

		if(TotalWeight > 0)
		{
			Out.BalanceWeight(TotalWeight);
		}

		return Out;
	}

	FHazeCameraFinalizedWeightedFocusTargetInfo GetEditorPreviewFocus(FHazeCameraWeightedFocusTargetInfo Target) const
	{
		FName PlayerType = Target.GetEditorPreviewPlayerDebugType();
		FTransform CameraTransform = Owner.ActorTransform;

		// Apply the player target transform
		{
			FTransform PlayerTransform;
			if(EditorDebugPlayerTargetTransforms.Find(PlayerType, PlayerTransform))
				CameraTransform.AddToTranslation(CameraTransform.Rotation.RotateVector(PlayerTransform.Location));
		}

		FHazeCameraFinalizedWeightedFocusTargetInfo Out;
		Target.GetEditorPreviewFocusTransform(CameraTransform, GetEditorViewRotation(), Out.Location, Out.Rotation);
		Out.Weight = Target.GetEditorPreviewWeight();

		if(Target.GetEditorPreviewShouldFocusOnUser())
			Out.PlayerTarget = EHazeCameraFinalizedWeightedFocusTargetPlayerType::Self;
		else if(Target.GetEditorPreviewShouldFocusOnOtherUser())
			Out.PlayerTarget = EHazeCameraFinalizedWeightedFocusTargetPlayerType::Other;

		return Out;
	}

	// Used for the "View Offset" in targetables
	FRotator GetEditorViewRotation() const
	{
		return GetOwner().GetActorRotation();
		//return Editor::EditorViewRotation;
	}

#endif

	FVector GetWeightedCenterFromTarget(FFocusTargets FocusTargets)
    {
        if (FocusTargets.Num() == 0)
		{
			check(false);
            return FVector::ZeroVector;
		}

        // Use offsets from first position so we'll reduce precision errors
        FVector Origin = FocusTargets[0].Location;
        FVector Offset = FVector::ZeroVector;
        float TotalWeight = FocusTargets[0].Weight;
        for (int i = 1; i < FocusTargets.Num(); i++)
        {
			const auto& Target = FocusTargets[i];
            Offset += (Target.Location - Origin) * Target.Weight;
            TotalWeight += Target.Weight;
        }

        if (TotalWeight == 0.0)
            return FVector::ZeroVector;
   
        return Origin + Offset;
    }

	bool ShouldFocusOnBothPlayers(AHazePlayerCharacter Player) const
	{
		check(bHasBegunPlay);
		auto FocusTargets = GetFocusTargets(Player);
		int PlayersFound = 0;
		for(auto It : FocusTargets.Targets)
		{
			if(It.PlayerTarget != EHazeCameraFinalizedWeightedFocusTargetPlayerType::None)
				PlayersFound++;
		}
		return PlayersFound == 2;
	}

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
			
			#if EDITOR
			const FString Category = FString(f"{i}#Target_{i + 1}: {Target.DebugActorName}");
			#else
			const FString Category = FString(f"{i}#Target_{i + 1}: {Target.DebugActorName}");
			#endif
			float DebugRadius = 50;

			FLinearColor DebugColor = GetTargetDebugColor(i);

			TemporalLog.Value(f"{Category};Target:", Target.DebugInfo);
			TemporalLog.Value(f"{Category};Weight:", Target.Weight);
			TemporalLog.Value(f"{Category};Offset:", LocalOffset);
			TemporalLog.Sphere(f"{Category};Location:", Target.Location, DebugRadius, Color = DebugColor);
			TemporalLog.Arrow(f"{Category};Find Target:", Player.ViewLocation, Target.Location, Color = DebugColor);
		}
	}
	#endif

	#if TEST
	FLinearColor GetTargetDebugColor(int Index) const
	{
		TArray<FLinearColor> DebugColors;
		DebugColors.Add(FLinearColor(FColor::Yellow));
		DebugColors.Add(FLinearColor(FColor::Purple));
		DebugColors.Add(FLinearColor(FColor::Emerald));
		DebugColors.Add(FLinearColor(FColor::Orange));
		DebugColors.Add(FLinearColor(FColor::Turquoise));
		return DebugColors[Math::WrapIndex(Index, 0, DebugColors.Num())];
	}
	#endif
}

#if EDITOR
class UCameraWeightedTargetComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCameraWeightedTargetComponent;

	FName DebugUserIndexSelected = NAME_None;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto TargetComponent = Cast<UCameraWeightedTargetComponent>(Component);

		auto Camera = UHazeCameraComponent::Get(TargetComponent.Owner);
		FVector CameraActorLocation = Camera.WorldLocation;

		const FVector ActorLocation = TargetComponent.Owner.ActorLocation;
		const FRotator ActorRotation = TargetComponent.Owner.ActorRotation;

		// Get all the debug types to draw
		// This is depending on what types we can target on
		TArray<FName> DebugUserTypes;
		TArray<FLinearColor> DebugUserColor;

		{
			if(TargetComponent.Targets.Num() == 0)
			{
				if(TargetComponent.EmptyTargetDefaultType == ECameraWeightedTargetEmptyInitType::DefaultToUser)
				{
					DebugUserTypes.Add(n"Player");
					DebugUserColor.Add(FLinearColor::LucBlue);
				}
				else if(TargetComponent.EmptyTargetDefaultType == ECameraWeightedTargetEmptyInitType::DefaultToBothUsers)
				{
					DebugUserTypes.Add(n"Player");
					DebugUserTypes.Add(n"OtherPlayer");
					DebugUserColor.Add(FLinearColor::LucBlue);
					DebugUserColor.Add(FLinearColor::Blue);
				}
				else if(TargetComponent.EmptyTargetDefaultType == ECameraWeightedTargetEmptyInitType::DefaultToBothPlayers)
				{
					DebugUserTypes.Add(n"Mio");
					DebugUserTypes.Add(n"Zoe");
					DebugUserColor.Add(FLinearColor::LucBlue);
					DebugUserColor.Add(FLinearColor::Blue);
				}
			}
			else
			{
				for(auto It : TargetComponent.Targets)
				{
					FName UserName = It.GetEditorPreviewPlayerDebugType();
					if(UserName != NAME_None)
					{
						int CurrentIndex = DebugUserTypes.FindIndex(UserName);
						if(CurrentIndex < 0)
						{
							DebugUserTypes.Add(UserName);
							DebugUserColor.Add(It.GetEditorPreviewDebugColor());
						}	
					}
				}	
			}

			auto OptionalTargetComponent = UCameraWeightedTargetOptionalComponent::Get(TargetComponent.Owner);
			if(OptionalTargetComponent != nullptr && OptionalTargetComponent.bUseCustomLocationTargets)
			{
				for(auto It : OptionalTargetComponent.CustomLocationTargets)
				{
					FName UserName = It.GetEditorPreviewPlayerDebugType();
					if(UserName != NAME_None)
					{
						int CurrentIndex = DebugUserTypes.FindIndex(UserName);
						if(CurrentIndex < 0)
						{
							DebugUserTypes.Add(UserName);
							DebugUserColor.Add(It.GetEditorPreviewDebugColor());
						}
						else
						{
							DebugUserColor[CurrentIndex] = FLinearColor::Teal;
						}
					}
				}
			}
		}

		if(DebugUserIndexSelected != NAME_None && !DebugUserTypes.Contains(DebugUserIndexSelected))
		{
			EndEditing();
			DebugUserIndexSelected = NAME_None;
		}

		for(int i = 0; i < DebugUserTypes.Num(); ++i)
		{
		
			FName UserEditableLocationType = DebugUserTypes[i];
			UserEditableLocationType.SetNumber(i + 1);
			bool bCurrentSelected = DebugUserIndexSelected == DebugUserTypes[i];
			
			FLinearColor DebugColor = (DebugUserIndexSelected == NAME_None) ? DebugUserColor[i] : FLinearColor::Gray;

			FTransform PlayerTypeTransform = FTransform::Identity;
			TargetComponent.EditorDebugPlayerTargetTransforms.Find(DebugUserTypes[i], PlayerTypeTransform);
			FVector WorldLocation = ActorLocation + ActorRotation.RotateVector(PlayerTypeTransform.Location);

			if(!bCurrentSelected)
			{
				SetHitProxy(UserEditableLocationType, EVisualizerCursor::GrabHand);
				DrawWireDiamond(WorldLocation, FRotator::ZeroRotator, 50, DebugColor, 1);
				ClearHitProxy();

				DrawDashedLine(CameraActorLocation, WorldLocation, DebugColor, 50);
				DrawWorldString(DebugUserTypes[i].ToString(), WorldLocation);
			}
			else
			{
				FTransform EditorTransform;
				float Fov;
				Camera.GetEditorPreviewTransform(EditorTransform, Fov);
				DrawWireDiamond(WorldLocation, FRotator::ZeroRotator, 60, FLinearColor::White, 1);
				DrawDashedLine(EditorTransform.Location, WorldLocation, FLinearColor::Black, 50);
				DrawWorldString(DebugUserTypes[i].ToString(), WorldLocation);
			}	


			if(TargetComponent.EditorDebugSpline != nullptr)
			{
				if(bCurrentSelected)
				{
					FVector SplineLocation = TargetComponent.EditorDebugSpline.GetClosestSplineWorldLocationToWorldLocation(WorldLocation);
					DrawDashedLine(WorldLocation, SplineLocation, FLinearColor::DPink, 50);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		DebugUserIndexSelected = NAME_None;
	}

	// Handle when the point with the hitproxy is clicked 
	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		DebugUserIndexSelected = NAME_None;
		auto TargetComponent = Cast<UCameraWeightedTargetComponent>(EditingComponent);
		if(TargetComponent == nullptr)
			return false;

		for(auto It : TargetComponent.EditorDebugPlayerTargetTransforms)
		{
			if (HitProxy.IsEqual(It.Key, bCompareNumber = false))
			{
				DebugUserIndexSelected = It.Key;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputKey(FKey Key, EInputEvent Event)
	{
		if(DebugUserIndexSelected == NAME_None)
			return false;

		if(Key != EKeys::LeftShift)
			return false;

		auto TargetComponent = Cast<UCameraWeightedTargetComponent>(EditingComponent);
		if(TargetComponent == nullptr)
			return false;
		
		FVector MouseOrigin, TraceDirection;
		Editor::GetEditorCursorRay(MouseOrigin, TraceDirection);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseLine();

		FVector WorldLocation = Editor::EditorViewLocation;
		auto HitResult = Trace.QueryTraceSingle(MouseOrigin, MouseOrigin + (TraceDirection * 10000));
		if(HitResult.IsValidBlockingHit())
		{
			WorldLocation = HitResult.Location;
			WorldLocation += HitResult.ImpactNormal * 32; // so the camera don't clip into the impact
		}
		else if(!HitResult.bBlockingHit)
		{
			WorldLocation = HitResult.TraceEnd;
		}

		FRotator LocalRotation = TargetComponent.Owner.ActorRotation.Inverse;
		FVector CurrentLocation = LocalRotation.RotateVector(WorldLocation - TargetComponent.Owner.ActorLocation);
		CurrentLocation += LocalRotation.RotateVector(Editor::EditorViewRotation.ForwardVector * 25);
		TargetComponent.EditorDebugPlayerTargetTransforms[DebugUserIndexSelected].SetLocation(CurrentLocation);

		return true;
	}

	// Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		if(DebugUserIndexSelected == NAME_None)
			return false;

		auto TargetComponent = Cast<UCameraWeightedTargetComponent>(EditingComponent);
		if(TargetComponent == nullptr)
			return false;

		FVector DebugLocation = TargetComponent.EditorDebugPlayerTargetTransforms[DebugUserIndexSelected].Location;
		OutLocation = TargetComponent.Owner.ActorLocation;
		OutLocation += TargetComponent.Owner.ActorRotation.RotateVector(DebugLocation);
		return true;	
	}

	// Used by the editor to determine what the coordinate system for the transform gizmo should be
	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem, EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if(DebugUserIndexSelected == NAME_None)
			return false;

		auto TargetComponent = Cast<UCameraWeightedTargetComponent>(EditingComponent);
		if(TargetComponent == nullptr)
			return false;

		FQuat DebugRotation = TargetComponent.EditorDebugPlayerTargetTransforms[DebugUserIndexSelected].Rotation;
		OutTransform.SetScale3D(FVector::OneVector);
		OutTransform.SetRotation(DebugRotation);
		return false;
	}


	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if(DebugUserIndexSelected == NAME_None)
			return false;

		auto TargetComponent = Cast<UCameraWeightedTargetComponent>(EditingComponent);
		if(TargetComponent == nullptr)
			return false;

		FRotator LocalRotation = TargetComponent.Owner.ActorRotation;
		DeltaTranslate = LocalRotation.UnrotateVector(DeltaTranslate);
		DeltaTranslate *= 0.5;

		auto& DebugTransform = TargetComponent.EditorDebugPlayerTargetTransforms[DebugUserIndexSelected];
		DebugTransform.AddToTranslation(DeltaTranslate);
		DebugTransform.SetRotation(DebugTransform.Rotator() + DeltaRotate);
		return true;
	}

}

#endif



