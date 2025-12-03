UCLASS(Abstract)
class AIslandStormdrainAcidCurtain : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// USceneComponent MovableRoot;

	// UPROPERTY(DefaultComponent, Attach = MovableRoot)
	// UDeathTriggerComponent DeathTrigger;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent NiagaraRoot;

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara1;
	default Niagara1.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara2;
	default Niagara2.bAutoActivate = false;
	default Niagara2.RelativeLocation = FVector(75.0 * 1, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara3;
	default Niagara3.bAutoActivate = false;
	default Niagara3.RelativeLocation = FVector(75.0 * 2, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara4;
	default Niagara4.bAutoActivate = false;
	default Niagara4.RelativeLocation = FVector(75.0 * 4, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara5;
	default Niagara5.bAutoActivate = false;
	default Niagara5.RelativeLocation = FVector(75.0 * 5, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara6;
	default Niagara6.bAutoActivate = false;
	default Niagara6.RelativeLocation = FVector(75.0 * 6, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara7;
	default Niagara7.bAutoActivate = false;
	default Niagara7.RelativeLocation = FVector(75.0 * 8, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara8;
	default Niagara8.bAutoActivate = false;
	default Niagara8.RelativeLocation = FVector(75.0 * 9, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara9;
	default Niagara9.bAutoActivate = false;
	default Niagara9.RelativeLocation = FVector(75.0 * 10, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara10;
	default Niagara10.bAutoActivate = false;
	default Niagara10.RelativeLocation = FVector(75.0 * 12, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara11;
	default Niagara11.bAutoActivate = false;
	default Niagara11.RelativeLocation = FVector(75.0 * 13, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = NiagaraRoot)
	UNiagaraComponent Niagara12;
	default Niagara12.bAutoActivate = false;
	default Niagara12.RelativeLocation = FVector(75.0 * 14, 0.0, 0.0);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandStormdrainAcidCurtainVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem NiagaraEffect;

	UPROPERTY(EditDefaultsOnly)
	FPlayerDeathDamageParams DeathParams;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor OverlapSphere;

	TArray<UNiagaraComponent> NiagaraComponents;
	float SqrSphereRadius;
	TMap<UNiagaraComponent, float> TimeOfActivate;
	TMap<UNiagaraComponent, float> TimeOfDeactivate;
	TSet<UNiagaraComponent> ActiveComponents;

	const float AcidGravity = -980.0;
	const float AcidDelayBeforeFalling = 0.2;
	const bool bAcidDebugLines = false;
	const float AcidLevelOffset = -1128.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<UNiagaraComponent> Temp;
		GetComponentsByClass(UNiagaraComponent, Temp);

		for(UNiagaraComponent Niagara : Temp)
		{
			Niagara.Asset = NiagaraEffect;
		}

		// if(OverlapSphere != nullptr)
		// 	MovableRoot.WorldLocation = OverlapSphere.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(UNiagaraComponent, NiagaraComponents);
		SqrSphereRadius = OverlapSphere.GetActorLocalBoundingBox(false).Extent.X * OverlapSphere.ActorScale3D.X;
		SqrSphereRadius = Math::Square(SqrSphereRadius);
		//MovableRoot.AttachToComponent(OverlapSphere.RootComponent, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(UNiagaraComponent Niagara : NiagaraComponents)
		{
			bool bShouldBeActive = OverlapSphere.ActorLocation.DistSquared(Niagara.WorldLocation) < SqrSphereRadius;
			if(bShouldBeActive != ActiveComponents.Contains(Niagara))
			{
				if(bShouldBeActive)
				{
					Niagara.Activate();
					TimeOfActivate.FindOrAdd(Niagara) = Time::GetGameTimeSeconds();
					ActiveComponents.Add(Niagara);
				}
				else
				{
					Niagara.Deactivate();
					TimeOfDeactivate.FindOrAdd(Niagara) = Time::GetGameTimeSeconds();
					ActiveComponents.Remove(Niagara);
				}
			}

			if(!bShouldBeActive)
				continue;

			float HighestHeight = NiagaraRoot.WorldLocation.Z;
			float LowestHeight = GetAcidLevelHeight();

			if(bShouldBeActive)
			{
				LowestHeight = HighestHeight + Time::GetGameTimeSince(TimeOfActivate.FindOrAdd(Niagara) + AcidDelayBeforeFalling) * AcidGravity;

				if(LowestHeight < GetAcidLevelHeight())
					LowestHeight = GetAcidLevelHeight();
			}
			else
			{
				HighestHeight = HighestHeight + Time::GetGameTimeSince(TimeOfDeactivate.FindOrAdd(Niagara)) * AcidGravity;

				if(HighestHeight < LowestHeight)
					continue;
			}

			FVector HighestPoint = FVector(Niagara.WorldLocation.X, Niagara.WorldLocation.Y, HighestHeight);
			FVector LowestPoint = FVector(Niagara.WorldLocation.X, Niagara.WorldLocation.Y, LowestHeight);
			FVector LowToHigh = HighestPoint - LowestPoint;
			float Length = LowToHigh.Size();

			FCollisionShape AcidShape = FCollisionShape::MakeCapsule(20.0, Length * 0.5);
			FTransform AcidTransform = FTransform(FRotator::ZeroRotator, (HighestPoint + LowestPoint) * 0.5);
			//Debug::DrawDebugCapsule(AcidTransform.Location, AcidShape.CapsuleHalfHeight, AcidShape.CapsuleRadius, AcidTransform.Rotator(), FLinearColor::Red);
			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(!Overlap::QueryShapeOverlap(AcidShape, AcidTransform, Player.CapsuleComponent.GetCollisionShape(), Player.CapsuleComponent.WorldTransform))
					continue;

				Player.KillPlayer(DeathParams, DeathEffect);
			}

			if(bAcidDebugLines)
				Debug::DrawDebugLine(HighestPoint, LowestPoint, FLinearColor::Red, 10.0);

			// if(bShouldBeActive)
			// 	Debug::DrawDebugPoint(Niagara.WorldLocation, 15.f, FLinearColor::Green);
		}

		//Debug::DrawDebugShape(DeathTrigger.Shape.GetCollisionShape(), DeathTrigger.WorldLocation, DeathTrigger.WorldRotation, FLinearColor::Red, 5.0);
	}

	float GetAcidLevelHeight() const
	{
		return NiagaraRoot.WorldLocation.Z + AcidLevelOffset;
	}
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UIslandStormdrainAcidCurtainVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandStormdrainAcidCurtainVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandStormdrainAcidCurtainVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Curtain = Cast<AIslandStormdrainAcidCurtain>(Component.Owner);
		FVector Start = FVector(Curtain.NiagaraRoot.WorldLocation.X, Curtain.NiagaraRoot.WorldLocation.Y, Curtain.GetAcidLevelHeight());
		DrawLine(Start, Start + Curtain.ActorForwardVector * 500.0, FLinearColor::Red, 3.0);
	}
}
#endif