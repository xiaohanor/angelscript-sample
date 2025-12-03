



UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class ATundraShapeShiftingDeathVolume : ADeathVolume
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(EditAnywhere, Meta=(EditCondition = bKillsMio, Bitmask, BitmaskEnum="/Script/Angelscript.ETundraShapeshiftActiveShape"), Category = "Death Volume")
	int KillsMioInShape = 0; 
	default KillsMioInShape |= 1 << int(ETundraShapeshiftActiveShape::Small);
	default KillsMioInShape |= 1 << int(ETundraShapeshiftActiveShape::Player);
	default KillsMioInShape |= 1 << int(ETundraShapeshiftActiveShape::Big);

	UPROPERTY(EditAnywhere, Meta=(EditCondition = bKillsZoe, Bitmask, BitmaskEnum="/Script/Angelscript.ETundraShapeshiftActiveShape"), Category = "Death Volume")
	int KillsZoeInShape = 0; 
	default KillsZoeInShape |= 1 << int(ETundraShapeshiftActiveShape::Small);
	default KillsZoeInShape |= 1 << int(ETundraShapeshiftActiveShape::Player);
	default KillsZoeInShape |= 1 << int(ETundraShapeshiftActiveShape::Big);

	private TArray<AHazePlayerCharacter> PlayersInside;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor) override
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		
		if(Player.HasControl())
		{
			PlayersInside.Add(Player);
			SetActorTickEnabled(true);
		}

		Super::ActorBeginOverlap(OtherActor);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		
		if(Player.HasControl())
		{
			PlayersInside.RemoveSingleSwap(Player);
			SetActorTickEnabled(PlayersInside.Num() > 0);
		}
	}

	bool IsEnabledForPlayer(AHazePlayerCharacter Player) const override
	{
		if(!Super::IsEnabledForPlayer(Player))
			return false;

		auto Shapeshift = UTundraPlayerShapeshiftingComponent::Get(Player);
		int ActiveShape = 1 << int(ETundraShapeshiftActiveShape::Player);
		if(Shapeshift.IsBigShape())
			ActiveShape = 1 << int(ETundraShapeshiftActiveShape::Big);
		else if(Shapeshift.IsSmallShape())
			ActiveShape = 1 << int(ETundraShapeshiftActiveShape::Small);

		if (Player.IsMio())
		{
			return KillsMioInShape & ActiveShape != 0;
		}
		else
		{
			return KillsZoeInShape & ActiveShape != 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// try again until we have the correct shape
		for(auto Player : PlayersInside)
		{
			if(!IsEnabledForPlayer(Player))
				continue;

			Player.KillPlayer(DeathEffect = DeathEffect);
		}
	}

}