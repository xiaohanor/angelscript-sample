
UCLASS(Abstract)
class UPlayerBabyDragonComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<ABabyDragon> BabyDragonClass;
	UPROPERTY()
	FName AttachSocket = n"Backpack";
	
	ABabyDragon BabyDragon;

	void RequestBabyDragonLocomotion(FName AnimationTag)
	{
		if(BabyDragon == nullptr)
			return;

		if(!BabyDragon.Mesh.CanRequestLocomotion())
			return;

		BabyDragon.Mesh.RequestLocomotion(AnimationTag, this);
	}

	void SpawnBabyDragon(AHazePlayerCharacter Player)
	{
		BabyDragon = SpawnActor(BabyDragonClass);
		BabyDragon.Player = Player;

		Outline::AddToPlayerOutline(BabyDragon.Mesh, Player, this, EInstigatePriority::Normal);
		
		auto RenderingSettings = UPlayerRenderingSettingsComponent::GetOrCreate(Player);
		RenderingSettings.AdditionalSubsurfaceMeshes.Add(BabyDragon.Mesh);
	}

	void AttachBabyDragon(AHazePlayerCharacter Player)
	{
		BabyDragon.AttachToComponent(Player.Mesh, AttachSocket);
	}

	void DettachBabyDragon(AHazePlayerCharacter Player)
	{
		BabyDragon.DetachFromActor(EDetachmentRule::KeepWorld);
		// BabyDragon.ActorLocation = Player.ActorLocation;
	}
};