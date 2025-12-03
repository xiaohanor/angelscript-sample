struct FSerpentSpikeGroupPlacementParams
{
	FSerpentSpikeGroupPlacementParams(FRotator InRotation, FVector InLocation)
	{
		Rotation = InRotation;
		Location = InLocation;
	}
	FRotator Rotation;
	FVector Location;
}

UCLASS(Abstract)
class ASerpentSpikeGroup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	TArray<ASerpentSpike> SpikeActors;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASerpentSpike> SerpentSpikeClass;

	bool bHasGrown;
	bool bHasSmashed;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.SpriteName = "S_Actor";
	default Visual.WorldScale3D = FVector(15.0);

	UPROPERTY(DefaultComponent)
	USerpentSpikeGroupDummyComponent DummyComp;

	UPROPERTY(EditAnywhere)
	int NumSpikesToPlace = 5;

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		float RotationAmountPerSpike = 360.0 / float(NumSpikesToPlace);
		for (int i = 0; i < NumSpikesToPlace; i++)
		{
			FRotator RotationDelta = FRotator(0, 0, RotationAmountPerSpike * i);
			FRotator NewRotation = ActorRotation + RotationDelta;
			Debug::DrawDebugLine(ActorLocation, ActorLocation + NewRotation.UpVector * 20000, FLinearColor::DPink, 50, 0, true);
		}
	}

	UFUNCTION(CallInEditor)
	void DeleteSpikes()
	{
		FScopedTransaction Transaction("Delete SpikeGroup Placed SerpentSpikes");
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (auto AttachedActor : AttachedActors)
		{
			auto Spike = Cast<ASerpentSpike>(AttachedActor);
			if (Spike != nullptr)
			{
				SpikeActors.AddUnique(Spike);
			}
		}

		for (auto Spike : SpikeActors)
		{
			Spike.DestroyActor();
		}
		SpikeActors.Empty();
	}

	UFUNCTION(CallInEditor)
	void PlaceSpikesInCircle()
	{
		DeleteSpikes();

		FScopedTransaction Transaction("SpikeGroup Place SerpentSpikes");
		float RotationAmountPerSpike = 360.0 / float(NumSpikesToPlace);
		FHazeTraceSettings Settings;
		Settings.TraceWithChannel(ECollisionChannel::ECC_WorldStatic);
		Settings.UseLine();
		TArray<FSerpentSpikeGroupPlacementParams> PlacementParams;
		for (int i = 0; i < NumSpikesToPlace; i++)
		{
			FRotator RotationDelta = FRotator(0, 0, RotationAmountPerSpike * i);
			FRotator NewRotation = ActorRotation + RotationDelta;
			auto HitResult = Settings.QueryTraceSingle(ActorLocation, ActorLocation + NewRotation.UpVector * 20000);
			if (HitResult.bBlockingHit)
			{
				PlacementParams.Add(FSerpentSpikeGroupPlacementParams(NewRotation, HitResult.ImpactPoint));
			}
		}
		for (auto Param : PlacementParams)
		{
			auto Spike = SpawnActor(SerpentSpikeClass, Param.Location, FRotator::MakeFromZ(-Param.Rotation.UpVector));
			SpikeActors.Add(Spike);
			Spike.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> OutActors;
		GetAttachedActors(OutActors, true);
		for (auto Actor : OutActors)
		{
			auto Spike = Cast<ASerpentSpike>(Actor);
			if (Spike == nullptr)
				continue;
			
			Spike.OnSerpentSpikeGrow.AddUFunction(this, n"OnSerpentSpikeGrow");
			Spike.OnSerpentSpikeSmashed.AddUFunction(this, n"OnSerpentSpikeSmashed");
			SpikeActors.AddUnique(Spike);
		}
	}

	UFUNCTION()
	private void OnSerpentSpikeGrow()
	{
		if (bHasGrown)
			return;

		bHasGrown = true;
		USerpentSpikeGroupEventHandler::Trigger_OnSpikeGroupGrow(this);
	}

	UFUNCTION()
	private void OnSerpentSpikeSmashed()
	{
		if (bHasSmashed)
			return;

		bHasSmashed = true;
		USerpentSpikeGroupEventHandler::Trigger_OnSpikeGroupSmash(this);
	}

	UFUNCTION()
	TArray<ASerpentSpike> GetSpikes()
	{
		return SpikeActors;
	}
};

#if EDITOR
class USerpentSpikeGroupDummyComponent : UActorComponent
{

}

class USerpentSpikeGroupDummyComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USerpentSpikeGroupDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USerpentSpikeGroupDummyComponent>(Component);
		if (Comp == nullptr)
			return;

		auto SpikeGroup = Cast<ASerpentSpikeGroup>(Comp.Owner);
		if (SpikeGroup == nullptr)
			return;

		DrawWireSphere(SpikeGroup.ActorLocation, 200, FLinearColor::Blue, 5, 12, true);
	}
}
#endif