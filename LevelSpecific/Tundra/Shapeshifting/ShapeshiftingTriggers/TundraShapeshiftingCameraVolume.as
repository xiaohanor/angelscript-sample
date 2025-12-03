// This will not run again when you change the player property
// class UTundraShapeshiftingCameraVolumeDetailsCustomization : UHazeScriptDetailCustomization
// {
// 	default DetailClass = ATundraShapeshiftingCameraVolume;

// 	UFUNCTION(BlueprintOverride)
// 	void CustomizeDetails()
// 	{
// 		auto CameraVolume = Cast<ATundraShapeshiftingCameraVolume>(CustomizedObject);

// 		if(CameraVolume.CameraSettings.Player == EHazeSelectPlayer::Zoe)
// 			HideProperty(n"TriggerForMioShape");
// 		else if(CameraVolume.CameraSettings.Player == EHazeSelectPlayer::Mio)
// 			HideProperty(n"TriggerForZoeShape");
// 	}
// }

class ATundraShapeshiftingCameraVolume : AHazeCameraVolume
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(EditAnywhere, Meta=(Bitmask, BitmaskEnum="/Script/Angelscript.ETundraShapeshiftActiveShape"), Category = "Settings")
	int TriggerForMioShape = 0; 
	default TriggerForMioShape |= 1 << int(ETundraShapeshiftActiveShape::Small);
	default TriggerForMioShape |= 1 << int(ETundraShapeshiftActiveShape::Player);
	default TriggerForMioShape |= 1 << int(ETundraShapeshiftActiveShape::Big);

	UPROPERTY(EditAnywhere, Meta=(Bitmask, BitmaskEnum="/Script/Angelscript.ETundraShapeshiftActiveShape"), Category = "Settings")
	int TriggerForZoeShape = 0; 
	default TriggerForZoeShape |= 1 << int(ETundraShapeshiftActiveShape::Small);
	default TriggerForZoeShape |= 1 << int(ETundraShapeshiftActiveShape::Player);
	default TriggerForZoeShape |= 1 << int(ETundraShapeshiftActiveShape::Big);

	TPerPlayer<UTundraPlayerShapeshiftingComponent> ShapeshiftComps;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(GetShapeshiftComps())
		{
			if(GetNumOverlappingUsers() == 0)
				SetActorTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		SetActorTickEnabled(true);

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(ShapeshiftComps[Player] != nullptr)
			{
				ShapeshiftComps[Player].OnChangeShape.Unbind(this, n"OnChangeShape");
				ShapeshiftComps[Player] = nullptr;
			}

			UnblockForPlayer(Player, this);
		}
	}

	bool IsShapeEnabledForPlayer(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape) const
	{
		int ActiveShape = 1 << uint(Shape);
		if (Player.IsMio())
		{
			return TriggerForMioShape & ActiveShape != 0;
		}
		else
		{
			return TriggerForZoeShape & ActiveShape != 0;
		}
	}

	bool GetShapeshiftComps()
	{
		// We already have the shapeshifting comps!
		if(ShapeshiftComps[0] != nullptr && ShapeshiftComps[1] != nullptr)
			return false;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);

			// Can't get shapeshifting comps yet, no bother trying to get the other player's since they are added at the same time.
			if(ShapeshiftComp == nullptr)
				return false;

			ShapeshiftComp.OnChangeShape.AddUFunction(this, n"OnChangeShape");
			ShapeshiftComps[Player] = ShapeshiftComp;
			OnChangeShape(Player, ShapeshiftComp.CurrentShapeType);
		}

		return true;
	}

	UFUNCTION()
	private void OnChangeShape(AHazePlayerCharacter Player, ETundraShapeshiftShape NewShape)
	{
		bool bShapeEnabled = IsShapeEnabledForPlayer(Player, ShapeshiftComps[Player].ActiveShapeType);
		if(!bShapeEnabled)
			BlockForPlayer(Player, this);
		else
			UnblockForPlayer(Player, this);
	}
}