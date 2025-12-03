
UCLASS(Abstract)
class UGameplay_Character_Boss_Tundra_IceKing_TundraBossHomingIceChunk_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnIceChunkExploded(FTundraBossHomingIceChunkEffectParams Params){}

	/* END OF AUTO-GENERATED CODE */

	ATundraBossHomingIceChunk IceChunk;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		IceChunk = Cast<ATundraBossHomingIceChunk>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return IceChunk.bIceChunkHidden == false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return IceChunk.bIceChunkHidden;
	}
}