class USanctuarySewerFloatingComponent : UActorComponent
{

	bool bIsOnWater;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Water = Cast<ASanctuarySewerWater>(Owner.AttachmentRootActor);

		
		

		if(Water == nullptr)
			return;

		bIsOnWater = true;

		Owner.AttachToComponent(Water.WaterRoot, NAME_None, EAttachmentRule::KeepWorld);
	}




};