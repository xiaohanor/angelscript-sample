
UCLASS(Abstract)
class UGameplay_Character_Boss_Skyline_BossTank_MortarBallFireManager_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASkylineBossTank BossTank;
	USkylineBossTankMortarBallComponent MortalBallComp;
	private TArray<FAkSoundPosition> FireSoundPositions;

	UPROPERTY(BlueprintReadOnly)
	float ClosestFirePlayerDistance = 0.0;

	TArray<ASkylineBossTankMortarBallFire> GetFires() const property
	{
		return MortalBallComp.MortarBallFires;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		BossTank = Cast<ASkylineBossTank>(HazeOwner);
		MortalBallComp = USkylineBossTankMortarBallComponent::Get(BossTank);
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
		const int NumFires = Fires.Num();
		if(NumFires > 0)
		{
			FireSoundPositions.Empty();
			FireSoundPositions.SetNum(NumFires * 2);
			ClosestFirePlayerDistance = MAX_flt;

			int FireSoundPositionIndex = 0;
			TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
			for(int i = 0; i < NumFires; ++i)
			{
				ASkylineBossTankMortarBallFire Fire = Fires[i];

				for(auto Player : Players)
				{
					FVector FireProjectedPlayerPos = Fire.ActorTransform.InverseTransformPosition(Player.ActorLocation);
					FireProjectedPlayerPos.Z = 0.0;
					const FVector PlayerPositionOnFireEdge = FireProjectedPlayerPos.GetSafeNormal() * Fire.Radius;
					const FVector PlayerPositionOnFireEdgeWorldPos = Fire.ActorTransform.TransformPosition(PlayerPositionOnFireEdge);
					const FVector ClosestFirePlayerWorldPos = Math::ClosestPointOnLine(Fire.ActorLocation, PlayerPositionOnFireEdgeWorldPos, Player.ActorLocation);

					FireSoundPositions[FireSoundPositionIndex].SetPosition(ClosestFirePlayerWorldPos);
					++FireSoundPositionIndex;

					const float PlayerDistSqrd = ClosestFirePlayerWorldPos.DistSquared(Player.ActorLocation);
					ClosestFirePlayerDistance = Math::Min(ClosestFirePlayerDistance, PlayerDistSqrd);
				}
			}

			ClosestFirePlayerDistance = Math::Sqrt(ClosestFirePlayerDistance);
		}

		DefaultEmitter.SetMultiplePositions(FireSoundPositions);
	}

}