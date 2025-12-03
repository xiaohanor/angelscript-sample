

enum EStencilEffectType
{
    Outline = 0,
    Gravity = 1,
    Stasis = 2,
    Cutout = 3,

	DisableAllOutlines = -1,
}

enum EStencilEffectEnablementState
{
	NoStencils,
	ActiveStencilsNotRendered,
	VisibleStencils,
}

struct FStencilEffectState
{
	int Asset;
	FInstigator Instigator;
	EInstigatePriority Priority;
}

struct FStencilEffectStateInstigated
{
	TArray<FStencilEffectState> StencilEffectStates;

	bool IsEmpty()
	{
		return StencilEffectStates.Num() == 0;
	}

	int Num()
	{
		return StencilEffectStates.Num();
	}

	// Gets the StencilEffectState with the highest priority;
	FStencilEffectState Get()
	{
		if(StencilEffectStates.Num() == 0)
		{
			FStencilEffectState nullResult;
			nullResult.Asset = -1;
			nullResult.Instigator = nullptr;
			return nullResult; // How do I return a null thing
		}

		// Find a FStencilEffectState with the highest priority
		EInstigatePriority HighestPriority = EInstigatePriority::Level;
		FStencilEffectState StencilEffectStateWithHighestPriority;
		for(FStencilEffectState State : StencilEffectStates)
		{
			if(State.Priority >= HighestPriority)
			{
				HighestPriority = State.Priority;
				StencilEffectStateWithHighestPriority = State;
			}
		}
		return StencilEffectStateWithHighestPriority;
	}

	// Applies an StencilEffectState with some priority
	void Apply(int Asset, FInstigator Instigator, EInstigatePriority Priority)
	{
		for (int i = StencilEffectStates.Num() - 1; i >= 0; i--)
		{
			FStencilEffectState State = StencilEffectStates[i];
			if((State.Asset == Asset) && (State.Instigator == Instigator) && (State.Priority == Priority))
			{
				// mvoe it to the top of the array
				StencilEffectStates.RemoveAt(i);
				StencilEffectStates.Add(State);
				return;
			}
		}

		FStencilEffectState StencilEffectState = FStencilEffectState();
		StencilEffectState.Asset = Asset;
		StencilEffectState.Instigator = Instigator;
		StencilEffectState.Priority = Priority;
		StencilEffectStates.Add(StencilEffectState);
	}

	// Clears all StencilEffectStates with a specific instigator
	void Clear(FInstigator Instigator)
	{
		for (int i = StencilEffectStates.Num() - 1; i >= 0; i--)
		{
			if(StencilEffectStates[i].Instigator == Instigator)
			{
				StencilEffectStates.RemoveAt(i);
			}
		}
	}
}

struct FOutlinePlayerCoverageChecks
{
	USceneComponent OtherPlayerMesh;
	TArray<FName> CoverageBones;
};

class UStencilEffectViewerComponent : UActorComponent
{
	UPROPERTY()
	TMap<UPrimitiveComponent, FStencilEffectStateInstigated> StencilEffectAssignments;
	
	UPROPERTY()
	TArray<UOutlineDataAsset> StencilEffectSlots;
	
	UPROPERTY()
	UMaterialInstanceDynamic UberShaderMaterialDynamic;
	
	UPROPERTY()
	UMaterialParameterCollection StencilParameters;

	UPROPERTY()
	UOutlineDataAsset PlayerOutline;

	UPROPERTY()
	UOutlineDataAsset EmptyOutline;

	TInstigated<FOutlinePlayerCoverageChecks> PlayerCoverageCheckBones;

	private const float PLAYER_OUTLINE_COVERAGE_THRESHOLD = 0.5;
	private TArray<bool> PlayerCoverageStatus;
	private int PlayerCoverageCheckIndex = 0;
	private float CurrentPlayerOutlineOpacity = 0.0;
	private bool bHasValidPlayerOutlineOpacity = false;
	private bool bWaitingForPlayerOutlineTrace = false;
	private bool bShowLeftViewportStencil = false;
	private bool bShowRightViewportStencil = false;
	private UPlayerOutlineSettings PlayerOutlineSettings;
	private UPlayerOutlineSettings OtherPlayerOutlineSettings;
	private UPostProcessingComponent PostProcessComp;
	private EStencilEffectEnablementState EnablementState = EStencilEffectEnablementState::NoStencils;

	bool bDirtyStencilEnablementState = false;
	TArray<bool> StencilSlotVisibility;

	// Called from PostProcessing.as
    void Init()
    {
		DevMenu::RequestTransientDevMenu(n"StencilEffects", "⭕️", UStencilEffectDevMenu);

		StencilEffectSlots.SetNumZeroed(16);
		SetDefaultCoverageBones();

		StencilSlotVisibility.SetNum(16);
		for (int i = 0, Count = StencilSlotVisibility.Num(); i < Count; ++i)
			StencilSlotVisibility[i] = true;

		
		if(UberShaderMaterialDynamic == nullptr)
			UberShaderMaterialDynamic = UPostProcessingComponent::Get(Owner).UberShaderMaterialDynamic;
		
		if(StencilParameters == nullptr)
			StencilParameters = UPostProcessingComponent::Get(Owner).StencilParameters;

		PostProcessComp = UPostProcessingComponent::Get(Owner);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
		PlayerOutlineSettings = UPlayerOutlineSettings::GetSettings(Player);
		OtherPlayerOutlineSettings = UPlayerOutlineSettings::GetSettings(Player.OtherPlayer);
		Outline::ApplyOutlineOnActor(Player.GetOtherPlayer(), Player, PlayerOutline, this, EInstigatePriority::Normal);
		UpdatePlayerOutline(0.0);
	}

	void SetDefaultCoverageBones()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(this.GetOwner());

		FOutlinePlayerCoverageChecks DefaultCoverage;
		DefaultCoverage.CoverageBones.Add(n"Neck");
		DefaultCoverage.CoverageBones.Add(n"LeftEye");
		DefaultCoverage.CoverageBones.Add(n"RightEye");
		DefaultCoverage.CoverageBones.Add(n"RightShoulder");
		DefaultCoverage.CoverageBones.Add(n"RightForeArm");
		DefaultCoverage.CoverageBones.Add(n"RightHand");
		DefaultCoverage.CoverageBones.Add(n"LeftShoulder");
		DefaultCoverage.CoverageBones.Add(n"LeftForeArm");
		DefaultCoverage.CoverageBones.Add(n"LeftHand");
		DefaultCoverage.CoverageBones.Add(n"LeftUpLeg");
		DefaultCoverage.CoverageBones.Add(n"LeftLeg");
		DefaultCoverage.CoverageBones.Add(n"LeftFoot");
		DefaultCoverage.CoverageBones.Add(n"RightUpLeg");
		DefaultCoverage.CoverageBones.Add(n"RightLeg");
		DefaultCoverage.CoverageBones.Add(n"RightFoot");

		PlayerCoverageCheckBones.SetDefaultValue(DefaultCoverage);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateViewportStencilAssociation();
		UpdatePlayerOutline(DeltaSeconds);

		// If we have stencils that are active, but not necessarily rendered, poll the enablement state
		// so that when they start rendering we can make the stencils visible 
		if (EnablementState != EStencilEffectEnablementState::NoStencils || bDirtyStencilEnablementState)
			UpdateStencilEnablementState();
	}

	void UpdateViewportStencilAssociation()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(this.GetOwner());
		const bool bShowBothViewports = SceneView::IsFullScreen();

		const bool bShowLeft = Player.IsMio() || bShowBothViewports;
		if (bShowLeft != bShowLeftViewportStencil)
		{
			if (bShowLeft)
			{
				UberShaderMaterialDynamic.SetScalarParameterValue(n"ShowLeftViewportStencils", 1.0);
				bShowLeftViewportStencil = true;
			}
			else
			{
				UberShaderMaterialDynamic.SetScalarParameterValue(n"ShowLeftViewportStencils", 0.0);
				bShowLeftViewportStencil = false;
			}
		}

		const bool bShowRight = Player.IsZoe() || bShowBothViewports;
		if (bShowRight != bShowRightViewportStencil)
		{
			if (bShowRight)
			{
				UberShaderMaterialDynamic.SetScalarParameterValue(n"ShowRightViewportStencils", 1.0);
				bShowRightViewportStencil = true;
			}
			else
			{
				UberShaderMaterialDynamic.SetScalarParameterValue(n"ShowRightViewportStencils", 0.0);
				bShowRightViewportStencil = false;
			}
		}
	}

	int GetPlayerOutlineSlot() const
	{
		int PlayerSlot = -1;
		for (int i = 0; i < StencilEffectSlots.Num(); i++)
		{
			if (StencilEffectSlots[i] == PlayerOutline)
			{
				PlayerSlot = i;
				break;
			}
		}

		return PlayerSlot;
	}

	void UpdatePlayerOutline(float DeltaTime)
	{
		// Find the outline slot that the player is using
		int PlayerSlot = GetPlayerOutlineSlot();
		if (PlayerSlot == -1)
			return;

		// Handle async traces from the camera to the other player's bones
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
		if (!bWaitingForPlayerOutlineTrace)
		{
			const FOutlinePlayerCoverageChecks& CoverageChecks = PlayerCoverageCheckBones.Get();
			PlayerCoverageCheckIndex = Math::WrapIndex(PlayerCoverageCheckIndex + 1, 0, CoverageChecks.CoverageBones.Num());

			USceneComponent CheckComponent = Player.OtherPlayer.Mesh;
			if (CoverageChecks.OtherPlayerMesh != nullptr)
				CheckComponent = CoverageChecks.OtherPlayerMesh;

			PlayerCoverageStatus.SetNum(CoverageChecks.CoverageBones.Num());

			FVector Start = Player.ViewLocation;
			FVector End = CheckComponent.GetSocketLocation(CoverageChecks.CoverageBones[PlayerCoverageCheckIndex]);

			FCollisionQueryParams QueryParams;
			QueryParams.AddIgnoredActor(Player);

			bWaitingForPlayerOutlineTrace = true;
			AsyncTrace::AsyncLineTraceByChannel(
				EAsyncTraceType::Single,
				Start, End,
				ECollisionChannel::ECC_Visibility,
				Params = QueryParams,
				InDelegate = FScriptTraceDelegate(this, n"OnPlayerOutlineTraceFinished"),
			);
		}

		// Determine the player's current coverage (how much of the outline we think is going to be visible)
		float Coverage = 0.0;
		const float CoveragePerBone = 1.0 / PlayerCoverageStatus.Num();
		for (bool bBoneCovered : PlayerCoverageStatus)
		{
			if (bBoneCovered)
				Coverage += CoveragePerBone;
		}

		// If the other player is _behind_ the camera, always consider it visible so we don't give it an outline
		if (Player.ViewRotation.ForwardVector.DotProduct(Player.OtherPlayer.ActorCenterLocation - Player.ViewLocation) < 0)
		{
			Coverage = 0;
			bHasValidPlayerOutlineOpacity = false;
		}

		// Check if the capability tag for outlines is blocked and make the outline go away then
		if (Player.OtherPlayer.IsCapabilityTagBlocked(CapabilityTags::Outline)
			|| Player.IsCapabilityTagBlocked(n"OtherPlayerOutline")
			|| Player.OtherPlayer.IsCapabilityTagBlocked(n"BlockedByCutscene")
			|| !OtherPlayerOutlineSettings.bPlayerOutlineVisible
		)
		{
			Coverage = 0;
		}

		// Depending on coverage, lerp the outline opacity
		if (Coverage < PLAYER_OUTLINE_COVERAGE_THRESHOLD)
		{
			if (!bHasValidPlayerOutlineOpacity)
			{
				CurrentPlayerOutlineOpacity = 0.0;
				bHasValidPlayerOutlineOpacity = true;
			}
			else
			{
				if (CurrentPlayerOutlineOpacity <= 0.0)
					return;
				CurrentPlayerOutlineOpacity = Math::FInterpConstantTo(CurrentPlayerOutlineOpacity, 0.0, DeltaTime, 4.0);
			}
		}
		else
		{
			if (!bHasValidPlayerOutlineOpacity)
			{
				CurrentPlayerOutlineOpacity = 1.0;
				bHasValidPlayerOutlineOpacity = true;
			}
			else
			{
				if (CurrentPlayerOutlineOpacity >= 1.0)
					return;
				CurrentPlayerOutlineOpacity = Math::FInterpConstantTo(CurrentPlayerOutlineOpacity, 1.0, DeltaTime, 4.0);
			}
		}

		// Apply the new outline opacity to the post process material
		FLinearColor Data0;
		FLinearColor Data1;
		FLinearColor Data2;

		PackOutlineData(PlayerOutline, Data0, Data1, Data2);

		Data1.R *= CurrentPlayerOutlineOpacity;
		Data1.G *= CurrentPlayerOutlineOpacity;

		ApplyOutlineData(PlayerSlot, Data0, Data1, Data2);

		// If the opacity is 0, turn off the stencil effect entirely to decrease rendering cost
		// Note that if _either_ player has a visible outline, _both_ players need to write to stencil, because
		// otherwise the outline will render on top of the player.
		UStencilEffectViewerComponent OtherPlayerStencilComponent = UStencilEffectViewerComponent::Get(Player.OtherPlayer);
		bool bOutlineVisible = (CurrentPlayerOutlineOpacity > 0 || OtherPlayerStencilComponent.CurrentPlayerOutlineOpacity > 0);
		SetStencilSlotVisible(PlayerSlot, bOutlineVisible);
		OtherPlayerStencilComponent.SetStencilSlotVisible(OtherPlayerStencilComponent.GetPlayerOutlineSlot(), bOutlineVisible);
	}

	bool IsStencilSlotVisible(int Slot) const
	{
		if (!StencilSlotVisibility.IsValidIndex(Slot))
			return false;
		if (StencilEffectSlots[Slot].Data.Type == EStencilEffectType::DisableAllOutlines)
			return false;
		return StencilSlotVisibility[Slot];
	}

	void SetStencilSlotVisible(int Slot, bool bVisible)
	{
		if (Slot == -1)
			return;
		if (StencilSlotVisibility[Slot] == bVisible)
			return;

		StencilSlotVisibility[Slot] = bVisible;

		bool bFinalVisibility = IsStencilSlotVisible(Slot);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
		for (auto Iterator : StencilEffectAssignments)
		{
			int UsedSlot = Iterator.Value.Get().Asset;
			if (UsedSlot == Slot)
			{
				if (bFinalVisibility)
					StencilEffect::SetStencilValue(Iterator.Key, Player, UsedSlot);
				else
					StencilEffect::SetStencilValue(Iterator.Key, Player, -1);
			}
		}

		UpdateStencilEnablementState();
	}

	private EStencilEffectEnablementState CalculateCurrentStencilEnablementState()
	{
		// If no stencil slots have an asset and are visible, we are don
		bool bAnySlotsVisible = false;
		for (int i = 0; i < StencilSlotVisibility.Num(); ++i)
		{
			if (StencilEffectSlots[i] == nullptr)
				continue;
			if (!IsStencilSlotVisible(i))
				continue;

			bAnySlotsVisible = true;
			break;
		}

		if (!bAnySlotsVisible)
			return EStencilEffectEnablementState::NoStencils;

		// Check that any assignments are active for a visible slot
		bool bAnyAssignmentsVisible = false;
		bool bAnyAssignmentsActiveNotRendered = false;
		for (auto Elem : StencilEffectAssignments)
		{
			if (!IsValid(Elem.Key))
			{
				Elem.RemoveCurrent();
				continue;
			}

			for (auto States : Elem.Value.StencilEffectStates)
			{
				if (!StencilEffectSlots.IsValidIndex(States.Asset))
					continue;
				if (StencilEffectSlots[States.Asset] == nullptr)
					continue;
				if (!IsStencilSlotVisible(States.Asset))
					continue;

				if (Elem.Key.WasRecentlyRendered())
					bAnyAssignmentsVisible = true;
				else
					bAnyAssignmentsActiveNotRendered = true;

				break;
			}

			if (bAnyAssignmentsVisible)
				break;
		}

		if (bAnyAssignmentsVisible)
			return EStencilEffectEnablementState::VisibleStencils;
		else if (bAnyAssignmentsActiveNotRendered)
			return EStencilEffectEnablementState::ActiveStencilsNotRendered;
		else
			return EStencilEffectEnablementState::NoStencils;
	}

	private void UpdateStencilEnablementState()
	{
		bDirtyStencilEnablementState = false;
		EnablementState = CalculateCurrentStencilEnablementState();

		if (EnablementState == EStencilEffectEnablementState::VisibleStencils)
			PostProcessComp.UberShaderEnablement.Apply(true, this);
		else
			PostProcessComp.UberShaderEnablement.Clear(this);
	}

	UFUNCTION()
	private void OnPlayerOutlineTraceFinished(uint64 TraceHandle, const TArray<FHitResult>&in OutHits, uint UserData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());

		bool bHasRelevantHit = false;
		for (FHitResult Hit : OutHits)
		{
			if (!Hit.bBlockingHit)
				continue;

			// Level streaming can cause the hit to be blocking, but the component and actor has been destroyed
			if(!IsValid(Hit.Component))
				continue;

			if (Hit.Component.IsAttachedTo(Player.RootComponent))
				continue;
			if (Hit.Component.IsAttachedTo(Player.OtherPlayer.RootComponent))
				continue;

			bHasRelevantHit = true;
			break;
		}

		PlayerCoverageStatus[PlayerCoverageCheckIndex] = bHasRelevantHit;
		bWaitingForPlayerOutlineTrace = false;
	}

	void PackOutlineData(UOutlineDataAsset Asset, FLinearColor& OutData0, FLinearColor& OutData1, FLinearColor& OutData2)
	{
		OutData0 = FLinearColor(0, 0, 0, int(Asset.Data.Type));
		OutData1 = FLinearColor(0, 0, 0, 0);
		OutData2 = FLinearColor(0, 0, 0, 0);
		if(Asset.Data.Type == EStencilEffectType::Outline)
		{
			OutData0.R = Asset.Data.Color.R;
			OutData0.G = Asset.Data.Color.G;
			OutData0.B = Asset.Data.Color.B;

			OutData1.R = Asset.Data.FillOpacity;
			OutData1.G = Asset.Data.BorderOpacity;
			OutData1.B = Asset.Data.BorderWidth;
			OutData1.A = float(Asset.Data.DisplayMode);

			OutData2.R = Asset.Data.TextureIndex;
			OutData2.G = Asset.Data.TextureTiling;
			OutData2.B = 0;
			OutData2.A = 0;
		}
	}

	void ApplyOutlineData(int Index, FLinearColor Data0, FLinearColor Data1, FLinearColor Data2)
	{
		FString Side;
		if (Owner == Game::Mio)
			Side = "Left";
		else
			Side = "Right";

		FName Name0 = FName("Stencil" + Side + "0_" + Index);
		FName Name1 = FName("Stencil" + Side + "1_" + Index);
		FName Name2 = FName("Stencil" + Side + "2_" + Index);

		Material::SetVectorParameterValue(StencilParameters, Name0, Data0);
		Material::SetVectorParameterValue(StencilParameters, Name1, Data1);
		Material::SetVectorParameterValue(StencilParameters, Name2, Data2);
	}
}

namespace StencilEffect
{
	void SetStencilValue(UPrimitiveComponent Comp, AHazePlayerCharacter Player, int NewValue)
	{
		if(Comp == nullptr || Player == nullptr)
			return;

		devCheck(NewValue < 15, "There are only 15 stencil masks available per viewport.");

		// HACK, we should alsoe make sure StencilEffectAssignments is cleaned up properly, either by enforcing users cleaning up atre themselves (in EndpPLay etc) or periodically
		if (!IsValid(Comp))
			return;

		int NewStencilValue = 0;
		if(Player == Game::Mio)
			NewStencilValue = ((NewValue + 1) << 4) | (Comp.CustomDepthStencilValue & 0x0F); // set upper 4 bits
		else
			NewStencilValue = ((NewValue + 1)) | (Comp.CustomDepthStencilValue & 0xF0); // set lower 4 bits

		if (Comp.CustomDepthStencilValue != NewStencilValue)
		{
			if (NewStencilValue == 0)
			{
				Comp.CustomDepthStencilValue = 0;
				Comp.SetRenderCustomDepth(false);
			}
			else
			{
				Comp.CustomDepthStencilValue = NewStencilValue;
				Comp.SetRenderCustomDepth(true);
			}

			Comp.MarkRenderStateDirty();
		}
	}
	
	UFUNCTION()
	void ApplyStencilEffect(UPrimitiveComponent Target, AHazePlayerCharacter Player, UOutlineDataAsset Asset, FInstigator Instigator, EInstigatePriority Priority)
	{
		if(Player == nullptr || Target == nullptr || Asset == nullptr || Instigator == nullptr)
			return;

		UStencilEffectViewerComponent StencilEffectViewerComponent = UStencilEffectViewerComponent::Get(Player);
		
		int Index = -1;
		bool bNewOutline = false;

		// Check if the asset is already there
		for(int i = 0; i < StencilEffectViewerComponent.StencilEffectSlots.Num(); i++)
		{
			UOutlineDataAsset StencilEffectDataAsset = StencilEffectViewerComponent.StencilEffectSlots[i];
			if(StencilEffectDataAsset == Asset)
			{
				Index = i;
				break;
			}
		}
		
		// Check if there are any empty slots
		if(Index == -1)
		{
			for(int i = 0; i < StencilEffectViewerComponent.StencilEffectSlots.Num(); i++)
			{
				UOutlineDataAsset StencilEffectDataAsset = StencilEffectViewerComponent.StencilEffectSlots[i];
				if(StencilEffectDataAsset == nullptr)
				{
					StencilEffectViewerComponent.StencilEffectSlots[i] = Asset;
					StencilEffectViewerComponent.StencilSlotVisibility[i] = true;
					Index = i;
					bNewOutline = true;
					break;
				}
			}
		}

		// Nowhere to put this outline, error!
		if(Index == -1)
		{
			devCheck(false, "Ran out of stencil/outline slots. Only 15 can be active at a time.");
			return;
		}

		StencilEffectViewerComponent.StencilEffectAssignments.FindOrAdd(Target).Apply(Index, Instigator, Priority);
		FStencilEffectState NewState = StencilEffectViewerComponent.StencilEffectAssignments.FindOrAdd(Target).Get();

		int NewIndex = NewState.Asset;
		if (!StencilEffectViewerComponent.IsStencilSlotVisible(NewIndex))
			NewIndex = -1;

		SetStencilValue(Target, Player, NewIndex);
		if (bNewOutline)
		{
			FLinearColor Data0;
			FLinearColor Data1;
			FLinearColor Data2;

			StencilEffectViewerComponent.PackOutlineData(Asset, Data0, Data1, Data2);
			StencilEffectViewerComponent.ApplyOutlineData(Index, Data0, Data1, Data2);
		}

		StencilEffectViewerComponent.bDirtyStencilEnablementState = true;
	}

	UFUNCTION()
	void ClearStencilEffect(UPrimitiveComponent Target, AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if(Player == nullptr || Target == nullptr || Instigator == nullptr)
			return;

		UStencilEffectViewerComponent StencilEffectViewerComponent = UStencilEffectViewerComponent::Get(Player);
		if(StencilEffectViewerComponent == nullptr)
			return;

		if(!StencilEffectViewerComponent.StencilEffectAssignments.Contains(Target))
			return;
		
		FStencilEffectStateInstigated& StencilEffectStateInstigated = StencilEffectViewerComponent.StencilEffectAssignments[Target];
		
		int Before = StencilEffectStateInstigated.Get().Asset;
		if (!StencilEffectViewerComponent.IsStencilSlotVisible(Before))
			Before = -1;

		StencilEffectStateInstigated.Clear(Instigator);

		int After = StencilEffectStateInstigated.Get().Asset;
		if (!StencilEffectViewerComponent.IsStencilSlotVisible(After))
			After = -1;
	
		if (Before != After)
		{
			SetStencilValue(Target, Player, After);
		}

		// Remove components
		if (StencilEffectStateInstigated.IsEmpty())
		{
			SetStencilValue(Target, Player, -1);
			StencilEffectViewerComponent.StencilEffectAssignments.Remove(Target);
		}
		
		// Loop over all the stencils and remove any ones that are not in use.
		for (int i = 0; i < StencilEffectViewerComponent.StencilEffectSlots.Num(); i++)
		{
			if(StencilEffectViewerComponent.StencilEffectSlots[i] == nullptr)
				continue;
			
			bool bFound = false;
			for (auto Iterator : StencilEffectViewerComponent.StencilEffectAssignments)
			{
				if (!IsValid(Iterator.Key))
				{
					Iterator.RemoveCurrent();
					continue;
				}

				for(auto A : Iterator.Value.StencilEffectStates)
				{
					if(A.Asset == i)
					{
						bFound = true;
						break;
					}
				}
			}

			if (!bFound)
			{
				StencilEffectViewerComponent.StencilEffectSlots[i] = nullptr;
				StencilEffectViewerComponent.StencilSlotVisibility[i] = true;
			}
		}

		StencilEffectViewerComponent.bDirtyStencilEnablementState = true;
	}
}