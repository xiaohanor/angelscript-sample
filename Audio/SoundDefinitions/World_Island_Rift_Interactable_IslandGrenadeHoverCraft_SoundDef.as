
UCLASS(Abstract)
class UWorld_Island_Rift_Interactable_IslandGrenadeHoverCraft_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStarted(FIslandGrenadeHoverCraftEffectParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void OnRedSwitchActivated() {};

	UFUNCTION(BlueprintEvent)
	void OnRedSwitchDeactivated() {};

	UFUNCTION(BlueprintEvent)
	void OnBlueSwitchActivated() {};

	UFUNCTION(BlueprintEvent)
	void OnBlueSwitchDeactivated() {};

	UPROPERTY(NotEditable)
	UHazeAudioEmitter RedPanelEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter BluePanelEmitter;

	private UPrimitiveComponent HoverCraftMesh;
	TArray<FAkSoundPosition> HoverCraftMultiSoundPositions;
	default HoverCraftMultiSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AIslandGrenadeHoverCraft HoverCraft = Cast<AIslandGrenadeHoverCraft>(HazeOwner);	

		AIslandPressurePlate BluePressurePlate = Cast<AIslandPressurePlate>(HoverCraft.AttachedActors[1]);
		AIslandPressurePlate RedPressurePlate = Cast<AIslandPressurePlate>(HoverCraft.AttachedActors[2]);
		AIslandHovercraftGrenadeLock RedGrenadeLock = Cast<AIslandHovercraftGrenadeLock>(HoverCraft.AttachedActors[3]);
		AIslandHovercraftGrenadeLock BlueGrenadeLock = Cast<AIslandHovercraftGrenadeLock>(HoverCraft.AttachedActors[4]);	
	
		
		RedPressurePlate.OnInteractionStarted.AddUFunction(this, n"OnRedSwitchActivated");
		RedPressurePlate.OnInteractionEnd.AddUFunction(this, n"OnRedSwitchDeactivated");
		RedPanelEmitter.AudioComponent.AttachToComponent(RedGrenadeLock.Root);
		
	
		BluePressurePlate.OnInteractionStarted.AddUFunction(this, n"OnBlueSwitchActivated");
		BluePressurePlate.OnInteractionEnd.AddUFunction(this, n"OnBlueSwitchDeactivated");
		BluePanelEmitter.AudioComponent.AttachToComponent(BlueGrenadeLock.Root);		

		HoverCraftMesh = UPrimitiveComponent::Get(HazeOwner, n"Audio");
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::GetPlayers())
		{
			FVector ClosestPlayerPos;	

			const float Dist = HoverCraftMesh.GetClosestPointOnCollision(Player.ActorLocation, ClosestPlayerPos);
			if(Dist < 0)
				ClosestPlayerPos = HoverCraftMesh.WorldLocation;
			
			HoverCraftMultiSoundPositions[Player.Player].SetPosition(ClosestPlayerPos);
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(HoverCraftMultiSoundPositions);
	}
}