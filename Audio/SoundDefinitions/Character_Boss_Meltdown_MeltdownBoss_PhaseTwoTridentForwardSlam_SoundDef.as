
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBoss_PhaseTwoTridentForwardSlam_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	const int NUM_ELECTRIC_BOLTS = 5;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UHazeAudioEmitter ForwardSlamMultiEmitter;
	private TArray<FAkSoundPosition> ForwardSlamSoundPositions;
	default ForwardSlamSoundPositions.SetNum(2);

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UHazeAudioEmitter ElectricBoltsMultiEmitter;
	private TArray<FAkSoundPosition> ElectricBoltsSoundPositions;
	default ElectricBoltsSoundPositions.SetNum(NUM_ELECTRIC_BOLTS);

	AMeltdownBossTridentForwardSlam ForwardSlam;

	TArray<USceneComponent> ElectricBoltAttaches;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ForwardSlam = Cast<AMeltdownBossTridentForwardSlam>(HazeOwner);

		TArray<USceneComponent> AttachComponents;
		ForwardSlam.GetComponentsByClass(UBillboardComponent, ElectricBoltAttaches);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{	
			const FVector PlayerPosition = Player.ActorLocation;
			FVector ShockwaveProjectedPlayerPos = ForwardSlam.ShockwaveMesh.WorldTransform.InverseTransformPositionNoScale(PlayerPosition);
			ShockwaveProjectedPlayerPos.Z = 0.0;
			const FVector ClosestPlayerPositionOnShockwaveEdge = ShockwaveProjectedPlayerPos.GetSafeNormal() * ForwardSlam.ShockwaveMesh.GetWorldScale().Max * 437.5;
			const FVector PlayerShockwaveWorldPos = ForwardSlam.ShockwaveMesh.WorldTransform.TransformPositionNoScale(ClosestPlayerPositionOnShockwaveEdge);

			ForwardSlamSoundPositions[int(Player.Player)].SetPosition(PlayerShockwaveWorldPos);
		}

		ForwardSlamMultiEmitter.SetMultiplePositions(ForwardSlamSoundPositions);

		const FVector MioPos = Game::Mio.ActorLocation;
		const FVector ZoePos = Game::Zoe.ActorLocation;
		for(int i = 0; i < NUM_ELECTRIC_BOLTS; ++i)
		{
			ElectricBoltsSoundPositions[i].SetPosition(ElectricBoltAttaches[i].WorldLocation);
		}

		ElectricBoltsMultiEmitter.SetMultiplePositions(ElectricBoltsSoundPositions);
	}
}