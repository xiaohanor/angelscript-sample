/**
 * Trigger a shapeshift during a cutscene
 */
UFUNCTION(BlueprintCallable)
void TundraShapeshiftCutscene(
	AHazeActor FromActor, AHazeActor ToActor,
	float BlendTime = 0.2,
	float FromActorScale = 1, float ToActorScale = 1,
	FLinearColor FromActorTint = FLinearColor::Gray, FLinearColor ToActorTint = FLinearColor::Gray,
	UAnimSequence FromActorScalePose = nullptr, UAnimSequence ToActorScalePose = nullptr)
{
	FromActor.ActorHiddenInGame = false;
	ToActor.ActorHiddenInGame = false;

	{
		FTundraCutsceneShapeshiftData FromActorShapeshiftData;
		FromActorShapeshiftData.BlendTime = BlendTime;
		FromActorShapeshiftData.Tint = FromActorTint;
		FromActorShapeshiftData.bHideMeshOnComplete = true;
		FromActorShapeshiftData.ScalePose = FromActorScalePose;
		FromActorShapeshiftData.Scale = FromActorScale;
		FromActorShapeshiftData.SourceSkelMesh = UHazeSkeletalMeshComponentBase::Get(ToActor);

		auto FromActorShapeshiftComp = UTundraCutsceneShapeshiftComponent::GetOrCreate(FromActor);
		FromActorShapeshiftComp.Shapeshift(FromActorShapeshiftData);
	}

	{
		FTundraCutsceneShapeshiftData ToActorShapeshiftData;
		ToActorShapeshiftData.bShapeshiftingTo = true;
		ToActorShapeshiftData.BlendTime = BlendTime;
		ToActorShapeshiftData.Tint = ToActorTint;
		ToActorShapeshiftData.ScalePose = ToActorScalePose;
		ToActorShapeshiftData.Scale = ToActorScale;
		ToActorShapeshiftData.SourceSkelMesh = UHazeSkeletalMeshComponentBase::Get(FromActor);

		auto ToActorShapeshiftComp = UTundraCutsceneShapeshiftComponent::GetOrCreate(ToActor);
		ToActorShapeshiftComp.Shapeshift(ToActorShapeshiftData);
	}
}

/**
 * Remove the component visual blocker on the player added by the shapeshift comp
 */
UFUNCTION(BlueprintCallable)
void TundraShapeshiftCutsceneShowPlayer(AHazePlayerCharacter Player)
{
	auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	Player.Mesh.RemoveComponentVisualsBlocker(ShapeShiftComp);
}

UFUNCTION(BlueprintCallable)
void TundraShapeshiftCutsceneShowShape(AHazePlayerCharacter Player, ETundraShapeshiftShape Shape)
{
	auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	ShapeShiftComp.GetMeshForShapeType(Shape).Owner.RemoveActorDisable(ShapeShiftComp);
}

UFUNCTION(BlueprintCallable)
void TundraShapeshiftCutsceneHideShape(AHazePlayerCharacter Player, ETundraShapeshiftShape Shape)
{
	auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	UHazeCharacterSkeletalMeshComponent Mesh = ShapeShiftComp.GetMeshForShapeType(Shape);
	Mesh.SetHiddenInGame(false);
	Mesh.Owner.AddActorDisable(ShapeShiftComp);
}

/**
 * To be called incase cutscene is skipped right in the middle of a shapeshift
 */
UFUNCTION(BlueprintCallable)
void TundraShapeshiftCutsceneSkipCleanup(AHazePlayerCharacter Player, ETundraShapeshiftShape FinalShape)
{
	auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	UHazeCharacterSkeletalMeshComponent MeshLarge = ShapeShiftComp.GetMeshForShapeType(ETundraShapeshiftShape::Big);
	UHazeCharacterSkeletalMeshComponent MeshSmall = ShapeShiftComp.GetMeshForShapeType(ETundraShapeshiftShape::Small);

	auto ShapeShiftCutsceneCompPlayer = UTundraCutsceneShapeshiftComponent::GetOrCreate(Player);
	if (ShapeShiftCutsceneCompPlayer != nullptr)
		ShapeShiftCutsceneCompPlayer.SetComplete();

	auto ShapeShiftCutsceneCompLarge = UTundraCutsceneShapeshiftComponent::Get(MeshLarge.Owner);
	if (ShapeShiftCutsceneCompLarge != nullptr)
		ShapeShiftCutsceneCompLarge.SetComplete();

	auto ShapeShiftCutsceneCompSmall = UTundraCutsceneShapeshiftComponent::Get(MeshSmall.Owner);
	if (ShapeShiftCutsceneCompSmall != nullptr)
		ShapeShiftCutsceneCompSmall.SetComplete();

	if (FinalShape != ETundraShapeshiftShape::Big)
		MeshLarge.Owner.AddActorDisable(ShapeShiftComp);
	if (FinalShape != ETundraShapeshiftShape::Small)
		MeshSmall.Owner.AddActorDisable(ShapeShiftComp);
	if (FinalShape != ETundraShapeshiftShape::Player)
		Player.Mesh.AddComponentVisualsBlocker(ShapeShiftComp);

	if (FinalShape == ETundraShapeshiftShape::Player)
		Player.Mesh.RemoveComponentVisualsBlocker(ShapeShiftComp);
	else if (FinalShape == ETundraShapeshiftShape::Small)
		MeshSmall.Owner.RemoveActorDisable(ShapeShiftComp);
	else if (FinalShape == ETundraShapeshiftShape::Big)
		MeshLarge.Owner.RemoveActorDisable(ShapeShiftComp);
}

struct FTundraCutsceneShapeshiftData
{
	UPROPERTY()
	bool bShapeshiftingTo = false;

	UPROPERTY()
	float Scale = 1;

	UPROPERTY()
	float BlendTime = 0.2;

	UPROPERTY()
	USkeletalMeshComponent SourceSkelMesh;

	UPROPERTY()
	FLinearColor Tint;

	UPROPERTY()
	bool bHideMeshOnComplete = false;

	UPROPERTY()
	UAnimSequence ScalePose;
}

event void FTundraCutsceneShapeshiftEvenet(FTundraCutsceneShapeshiftData Data);

class UTundraCutsceneShapeshiftComponent : UActorComponent
{
	UPROPERTY()
	FTundraCutsceneShapeshiftEvenet OnShapeshift;

	UPROPERTY()
	FTundraCutsceneShapeshiftData ShapeshiftData;

	float ShapeshiftTimeLeft = 0;
	int TickDelay = 0;

	UHazeSkeletalMeshComponentBase OwningSkelMesh;

	TMap<UMaterialInstanceDynamic, FLinearColor> DefaultTintColorMap;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ComponentTickEnabled = false;

		OwningSkelMesh = UHazeSkeletalMeshComponentBase::Get(Owner);

		devCheck(OwningSkelMesh != nullptr, "Character doesn't have a haze skeletal mesh comp");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Delay the effects a few frames, due to how the AnimInstance works
		if (TickDelay > 0)
		{
			TickDelay--;
			return;
		}

		if (ShapeshiftTimeLeft <= 0)
		{
			OnShapeshiftComplete();
			return;
		}

		float EffectAlpha = ShapeshiftTimeLeft / ShapeshiftData.BlendTime;
		if (ShapeshiftData.bShapeshiftingTo)
		{
			EffectAlpha = 1 - EffectAlpha;
		}

		// Dither Fade
		const float DitherFade = Math::Clamp(EffectAlpha * 1.3, 0.0, 1.0);
		OwningSkelMesh.SetScalarParameterValueOnMaterials(n"DitherFade", DitherFade);

		// Color Tint
		float ColorTintAlpha = Math::Clamp((1 - EffectAlpha) * 1.4, 0.0, 1.0);
		for (auto& MaterialMap : DefaultTintColorMap)
		{
			FLinearColor TintColor = Math::Lerp(MaterialMap.Value, ShapeshiftData.Tint, ColorTintAlpha);
			MaterialMap.Key.SetVectorParameterValue(n"Tint", TintColor);
		}

		ShapeshiftTimeLeft -= DeltaSeconds;
	}

	UFUNCTION(BlueprintCallable)
	void Shapeshift(FTundraCutsceneShapeshiftData InShapeshiftData)
	{
		if (ShapeshiftTimeLeft > 0)
		{
			devCheck(false, "Cannot trigger a new shapeshift while another one is already runninng!");
			return;
		}
		ShapeshiftData = InShapeshiftData;

		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
		{
			auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
			Player.Mesh.RemoveComponentVisualsBlocker(ShapeShiftComp);
		}
		else
		{
			if (Owner.AttachParentActor != nullptr)
			{
				auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Owner.AttachParentActor);
				if (ShapeShiftComp != nullptr)
					Owner.RemoveActorDisable(ShapeShiftComp);
				else
					OwningSkelMesh.SetHiddenInGame(false);
			}
			else
				OwningSkelMesh.SetHiddenInGame(false);
		}

		auto CopyPoseMesh = UHazeAnimCopyPoseFromMeshComponent::GetOrCreate(Owner);
		CopyPoseMesh.SetSourceMeshComponent(InShapeshiftData.SourceSkelMesh);

		OnShapeshift.Broadcast(InShapeshiftData);

		ComponentTickEnabled = true;

		ShapeshiftTimeLeft = InShapeshiftData.BlendTime;

		TickDelay = 1;

		// Make sure mesh is "hidden" by dither fade first frame
		if (ShapeshiftData.bShapeshiftingTo)
		{
			OwningSkelMesh.SetScalarParameterValueOnMaterials(n"DitherFade", 0);
		}

		// Store reference to the default tint colors
		for (int MaterialIndex = 0; MaterialIndex < OwningSkelMesh.Materials.Num(); MaterialIndex++)
		{
			auto Material = OwningSkelMesh.Materials[MaterialIndex];

			auto DynamicMaterial = Cast<UMaterialInstanceDynamic>(Material);
			if (DynamicMaterial == nullptr)
			{
				DynamicMaterial = OwningSkelMesh.CreateDynamicMaterialInstance(MaterialIndex, Material);
				if (DynamicMaterial == nullptr)
					continue;
			}

			if (!DefaultTintColorMap.Contains(DynamicMaterial))
			{
				auto DefaultTint = DynamicMaterial.GetVectorParameterValue(n"Tint");
				DefaultTintColorMap.Add(DynamicMaterial, DefaultTint);
			}
		}
	}

	void SetComplete()
	{
		if (ShapeshiftTimeLeft > 0)
		{
			ShapeshiftTimeLeft = 0;
			OnShapeshiftComplete();
		}
	}

	void OnShapeshiftComplete()
	{
		ComponentTickEnabled = false;
		ShapeshiftTimeLeft = 0;

		OwningSkelMesh.SetScalarParameterValueOnMaterials(n"DitherFade", 1);
		for (auto& MaterialMap : DefaultTintColorMap)
		{
			MaterialMap.Key.SetVectorParameterValue(n"Tint", MaterialMap.Value);
		}

		if (ShapeshiftData.bHideMeshOnComplete)
		{
			auto Player = Cast<AHazePlayerCharacter>(Owner);
			if (Player != nullptr)
			{
				auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
				Player.Mesh.AddComponentVisualsBlocker(ShapeShiftComp);
			}
			else
			{
				if (Owner.AttachParentActor != nullptr)
				{
					auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Owner.AttachParentActor);
					if (ShapeShiftComp != nullptr)
						Owner.AddActorDisable(ShapeShiftComp);
					else
						OwningSkelMesh.SetHiddenInGame(true);
				}
				else
					OwningSkelMesh.SetHiddenInGame(true);
			}
		}
		else
		{
			auto Player = Cast<AHazePlayerCharacter>(Owner);
			if (Player != nullptr)
			{
				auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
				Player.Mesh.RemoveComponentVisualsBlocker(ShapeShiftComp);
			}
			else
			{
				if (Owner.AttachParentActor != nullptr)
				{
					auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Owner.AttachParentActor);
					if (ShapeShiftComp != nullptr)
						Owner.RemoveActorDisable(ShapeShiftComp);
					else
						OwningSkelMesh.SetHiddenInGame(false);
				}
				else
					OwningSkelMesh.SetHiddenInGame(false);
			}
		}
	}
};