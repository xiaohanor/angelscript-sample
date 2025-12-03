UCLASS(NotBlueprintable)
class UTreeGuardianRangedShootHideOnCameraOverlapComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UTreeGuardianRangedShootHideOnCameraOverlapContainerComponent::GetOrCreate(Game::Zoe).ActorsToHide.AddUnique(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UTreeGuardianRangedShootHideOnCameraOverlapContainerComponent::GetOrCreate(Game::Zoe).ActorsToHide.RemoveSingleSwap(Owner);
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UTreeGuardianRangedShootHideOnCameraOverlapContainerComponent : UActorComponent
{
	TArray<AActor> ActorsToHide;

	private AHazePlayerCharacter Player;
	TArray<UMeshComponent> HiddenMeshes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::Zoe;
	}

	void HideOverlappedMeshes()
	{
		if(ActorsToHide.Num() == 0)
			return;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Camera);
		Trace.UseSphereShape(300.0);
		Trace.DebugDraw(2.0);
		FHitResultArray Hits = Trace.QueryTraceMulti(Player.ActorCenterLocation, Player.ActorCenterLocation - Player.ActorForwardVector * 500.0);
		for(FHitResult Hit : Hits.BlockHits)
		{
			if(!ActorsToHide.Contains(Hit.Actor))
				continue;

			Hit.Actor.GetComponentsByClass(UMeshComponent, HiddenMeshes);
		}

		for(UMeshComponent Mesh : HiddenMeshes)
		{
			Mesh.SetRenderedForPlayer(Player, false);
		}
	}

	void ShowOverlappedMeshes()
	{
		for(UMeshComponent Mesh : HiddenMeshes)
		{
			Mesh.SetRenderedForPlayer(Player, true);
		}

		HiddenMeshes.Reset();
	}
}