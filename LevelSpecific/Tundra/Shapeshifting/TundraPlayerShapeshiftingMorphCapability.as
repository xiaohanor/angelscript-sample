class UTundraPlayerShapeshiftingMorphCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::Shapeshifting);
	default CapabilityTags.Add(TundraShapeshiftingTags::ShapeshiftingMorph);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 2;

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UPlayerInteractionsComponent InteractionsComp;
	UTundraPlayerShapeshiftingSettings Settings;

	float Internal_MorphAlpha = 0.0;
	int DelayMorphFrames;
	int CurrentMorphDirection;
	bool bShouldMorphOtherDirection = false;
	bool bInterupedTransition = false;

	// True if shapeshifting directly from small to big or vice versa (bypassing player).
	bool bDoubleShapeshift = false;

	TMap<UMaterialInterface, FLinearColor> DefaultTintColorMap;

	ETundraShapeshiftShape FromShape = ETundraShapeshiftShape::None;
	ETundraShapeshiftShape ToShape = ETundraShapeshiftShape::Player;

	FLinearColor TransformingFromTint, TransformingToTint;
	UHazeCharacterSkeletalMeshComponent TransformingFromMesh, TransformingToMesh;
	bool bBlockedInteractions = false;
	bool bInInteraction = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		InteractionsComp = UPlayerInteractionsComponent::Get(Player);
		Settings = UTundraPlayerShapeshiftingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Currently displayed mesh is not 
		if(ShapeshiftingComp.CurrentShapeType == ToShape)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraPlayerShapeshiftingMorphDeactivatedParams& Params) const
	{
		if(!ShapeshiftingComp.bIsMorphing)
			return true;

		// Shapeshifted during morph
		if(ShapeshiftingComp.CurrentShapeType != ToShape)
		{
			// If new shape shouldn't morph in, just cancel current morph and snap in to new shape
			if(!ShapeshiftingComp.ShouldUseActivationEffect())
			{
				Params.bShouldSnap = true;
				return true;
			}

			int NewMorphDirection = GetShapeshiftDirectionForShapes(ToShape, ShapeshiftingComp.CurrentShapeType);
			// Should morph other direction if direction has changed and current shapeshift is not a double shapeshift.
			if(CurrentMorphDirection != NewMorphDirection && !bDoubleShapeshift)
			{
				Params.bShouldMorphOtherDirection = true;
				return true;
			}
		}

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(InteractionsComp.ActiveInteraction == nullptr)
		{
			Player.BlockCapabilities(CapabilityTags::Interaction, this);
			bBlockedInteractions = true;
			bInInteraction = false;
		}
		else
		{
			bInInteraction = true;
		}
		
		// Block morphing so fail morph will complete before morphing to a potential new shape
		if(!ShapeshiftingComp.bIsMorphing)
			Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingMorph, this);

		CurrentMorphDirection = GetShapeshiftDirectionForShapes(ToShape, ShapeshiftingComp.CurrentShapeType);
		bDoubleShapeshift = GetShapeshiftDelta(ToShape, ShapeshiftingComp.CurrentShapeType) > 1;

		if(bShouldMorphOtherDirection)
		{
			MorphAlpha = 1.0 - MorphAlpha;
			bShouldMorphOtherDirection = false;
			bInterupedTransition = true;
		}
		else
		{
			bInterupedTransition = false;
			MorphAlpha = 0.0;
		}

		FromShape = ToShape;
		ToShape = ShapeshiftingComp.CurrentShapeType;
		SetMeshesAndTints();

		SetVisibilityForShape(ToShape, true);

		if(ShapeshiftingComp.ShouldUseActivationEffect())
		{
			ShapeshiftingComp.bIsMorphing = true;
			ShapeshiftingComp.CurrentMorphDuration = Settings.MorphTime;
		}
		else
		{
			SetVisibilityForShape(FromShape, false);
		}

		DelayMorphFrames = 0;

		if(ShapeshiftingComp.ShouldUseActivationEffect())
		{
			Player.Mesh.RequestOverrideFeature(n"Shapeshift", this);
			if (bInterupedTransition)
			{
				TransformingFromMesh.SetAnimBoolParam(n"InterupedShapeShift", true);
				TransformingToMesh.SetAnimBoolParam(n"InterupedShapeShift", true);
				DelayMorphFrames = 2; // Delay the morph 2 frames
			}
		}

		// Just to be sure it's been removed
		TransformingToMesh.RemoveTickPrerequisiteComponent(TransformingFromMesh);
		TransformingFromMesh.AddTickPrerequisiteComponent(TransformingToMesh);
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraPlayerShapeshiftingMorphDeactivatedParams Params)
	{
		if(bBlockedInteractions)
		{
			Player.UnblockCapabilities(CapabilityTags::Interaction, this);
			bBlockedInteractions = false;
		}

		ShapeshiftingComp.CurrentMorphDuration = 0.0;

		if(MorphAlpha == 1.0)
			SetVisibilityForShape(FromShape, false);

		bShouldMorphOtherDirection = Params.bShouldMorphOtherDirection;

		// Reset the DitherFade value
		ResetMaterialParameters(TransformingToMesh);
		ResetMaterialParameters(TransformingFromMesh);

		if(!Params.bShouldSnap)
		{
			FTundraShapeshiftingEffectParams EffectParams;
			EffectParams.FromShape = FromShape;
			EffectParams.ToShape = ToShape;
			UTundraShapeshiftingEffectHandler::Trigger_OnShapeshiftMorphDone(Player, EffectParams);
		}
		
		if(Params.bShouldSnap || IsBlocked())
		{
			MorphAlpha = 1.0;
			ShapeshiftingComp.bIsMorphing = false;

			ETundraShapeshiftShape NewShape = ShapeshiftingComp.CurrentShapeType;

			if(NewShape != FromShape)
				SetVisibilityForShape(FromShape, false);
			if(NewShape != ToShape)
				SetVisibilityForShape(ToShape, false);

			if(NewShape != FromShape && NewShape != ToShape)
				SetVisibilityForShape(NewShape, true);

			ToShape = NewShape;
		}


		if(!ShapeshiftingComp.bIsMorphing)
			Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingMorph, this);

		TransformingFromMesh.RemoveTickPrerequisiteComponent(TransformingToMesh);
	}

	void ResetMaterialParameters(UHazeCharacterSkeletalMeshComponent Mesh)
	{
		for (auto Material : Mesh.Materials)
		{
			auto DynamicMaterial = Cast<UMaterialInstanceDynamic>(Material);
			if (DynamicMaterial != nullptr)
			{
				DynamicMaterial.SetScalarParameterValue(n"DitherFade", 1);
				
				FLinearColor DefaultTint;
				if (DefaultTintColorMap.Find(Material, DefaultTint))
					DynamicMaterial.SetVectorParameterValue(n"Tint", DefaultTint);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(!ShapeshiftingComp.ShouldUseActivationEffect())
			return;

		// If we are in an interaction, that means that we entered the interaction as a non-player, so the morph will happen while the enter is happening.
		// Morph wont work if we aren't requesting a feature, so we just request Movement.
		if(bInInteraction && Player.Mesh.CanRequestLocomotion())
		{
			Player.Mesh.RequestLocomotion(n"Movement", this);
		}

		if (DelayMorphFrames > 0)
			DelayMorphFrames--;
		else
			MorphAlpha += (DeltaTime / ShapeshiftingComp.CurrentMorphDuration);

		if(MorphAlpha >= 1.0)
		{
			MorphAlpha = 1.0;
			ShapeshiftingComp.bIsMorphing = false;
		}

		// Dither in/out the mesh
		if (TransformingToMesh != nullptr && TransformingFromMesh != nullptr)
		{
			TransformingToMesh.SetScalarParameterValueOnMaterials(n"DitherFade", Math::Clamp(MorphAlpha * 1.5, 0.0, 1.0));
			TransformingFromMesh.SetScalarParameterValueOnMaterials(n"DitherFade", (1 - MorphAlpha) * 1.2);

			for (auto Material : TransformingFromMesh.Materials)
			{
				auto DynamicMaterial = Cast<UMaterialInstanceDynamic>(Material);
				if (DynamicMaterial == nullptr)
					continue;
				
				FLinearColor DefaultTint = FLinearColor::Gray;
				if (!DefaultTintColorMap.Find(Material, DefaultTint))
				{
					DefaultTint = DynamicMaterial.GetVectorParameterValue(n"Tint");
					DefaultTintColorMap.Add(Material, DefaultTint);
				}

				FLinearColor TintColor = Math::Lerp(DefaultTint, TransformingFromTint, MorphAlpha * 1.5);
				DynamicMaterial.SetVectorParameterValue(n"Tint", TintColor);
			}

			for (auto Material : TransformingToMesh.Materials)
			{
				auto DynamicMaterial = Cast<UMaterialInstanceDynamic>(Material);
				if (DynamicMaterial == nullptr)
					continue;
				
				FLinearColor DefaultTint = FLinearColor::Gray;
				if (!DefaultTintColorMap.Find(Material, DefaultTint))
				{
					DefaultTint = DynamicMaterial.GetVectorParameterValue(n"Tint");
					DefaultTintColorMap.Add(Material, DefaultTint);
				}

				FLinearColor TintColor = Math::Lerp(TransformingToTint, DefaultTint, MorphAlpha);
				DynamicMaterial.SetVectorParameterValue(n"Tint", TintColor);
			}
		}
	}

	float GetMorphAlpha() property
	{
		return Internal_MorphAlpha;
	}

	void SetMorphAlpha(float NewAlpha) property
	{
		Internal_MorphAlpha = NewAlpha;
		ShapeshiftingComp.AnimData.MorphAlpha = NewAlpha;
	}

	int GetShapeshiftDirectionForShapes(ETundraShapeshiftShape From, ETundraShapeshiftShape To) const
	{
		return Math::Sign(int(To) - int(From));
	}

	int GetShapeshiftDelta(ETundraShapeshiftShape A, ETundraShapeshiftShape B) const
	{
		return Math::Abs(int(A) - int(B));
	}

	void SetMeshesAndTints()
	{
		TransformingFromMesh = ShapeshiftingComp.GetMeshForShapeType(FromShape);
		TransformingToMesh = ShapeshiftingComp.GetMeshForShapeType(ToShape);

		// Get material color tint
		if (ToShape == ETundraShapeshiftShape::Player)
		{
			auto ShapeComp = ShapeshiftingComp.GetShapeComponentForType(FromShape);
			ShapeComp.GetMaterialTintColors(TransformingToTint, TransformingFromTint);
		}
		else
		{
			auto ShapeComp = ShapeshiftingComp.GetShapeComponentForType(ToShape);
			ShapeComp.GetMaterialTintColors(TransformingFromTint, TransformingToTint);
		}
	}

	void SetVisibilityForShape(ETundraShapeshiftShape Shape, bool bVisibility)
	{
		if(Shape == ETundraShapeshiftShape::Player)
		{
			if(bVisibility)
			{
				Player.Mesh.RemoveComponentVisualsBlocker(ShapeshiftingComp);
				Player.Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
			}
			else
			{
				Player.Mesh.ResetAllAnimation();
				Player.Mesh.AddComponentVisualsBlocker(ShapeshiftingComp);
				Player.Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickMontagesWhenNotRendered;
			}

			return;
		}

		auto Mesh = ShapeshiftingComp.GetMeshForShapeType(Shape);
		if(bVisibility)
		{
			Mesh.Owner.RemoveActorDisable(ShapeshiftingComp);
			Mesh.SetHiddenInGame(false);
			Mesh.HazeForceUpdateAnimation(); // To ensure the animation is updated this tick, we need to force update it
		}
		else
		{
			Mesh.ResetAllAnimation();
			Mesh.Owner.AddActorDisable(ShapeshiftingComp);
		}
	}
}

struct FTundraPlayerShapeshiftingMorphDeactivatedParams
{
	bool bShouldMorphOtherDirection = false;
	bool bShouldSnap = false;
}