
UCLASS(Abstract)
class UVO_Island_StormDrain_SiloSentry_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSideExtendStart(){}

	UFUNCTION(BlueprintEvent)
	void OnExtendComplete(){}

	UFUNCTION(BlueprintEvent)
	void OnExtendStart(){}

	UFUNCTION(BlueprintEvent)
	void OnStopTelegraphing(){}

	UFUNCTION(BlueprintEvent)
	void OnStartTelegraphing(FIslandBeamTurretronTelegraphingParams IslandBeamTurretronTelegraphingParams){}

	UFUNCTION(BlueprintEvent)
	void OnStartTelegraphingTrackingLaser(FIslandBeamTurretronTelegraphingParams IslandBeamTurretronTelegraphingParams){}

	UFUNCTION(BlueprintEvent)
	void OnDamage(FIslandBeamTurretronProjectileImpactParams IslandBeamTurretronProjectileImpactParams){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(FIslandBeamTurretronOnDeathParams IslandBeamTurretronOnDeathParams){}

	/* END OF AUTO-GENERATED CODE */

TPerPlayer<UPlayerSwingComponent> SwingComps; //vi trackar en swing-component/player, skickar in en spelare, får ut en swing-comp
UFUNCTION(BlueprintOverride)
void ParentSetup() //setup for AS, run once as the SD is created
{
    SwingComps[PlayerOwner] = UPlayerSwingComponent::Get(PlayerOwner); //send playerowner in the component, swing comps map has 2 entries, one for player one for other player. this is a "map" aka dictionary. Players are key, swing comp is value
    SwingComps[PlayerOwner.OtherPlayer] = UPlayerSwingComponent::Get(PlayerOwner.OtherPlayer); // get other players swing comp as value
}
UFUNCTION(BlueprintPure)
bool IsAnyPlayerSwinging()
{
    //"for each loop" --- for each swing comp in swingcomps, 
    for(auto SwingComp : SwingComps) 
    {
        if (SwingComp.HasActivateSwingPoint())
            return true;
        
    }
    return false;
}
UFUNCTION(BlueprintPure)
bool AreBothPlayersSwinging()
{
    //"for each loop" --- for each swing comp in swingcomps, 
    for(auto SwingComp : SwingComps) 
    { 
        if (!SwingComp.HasActivateSwingPoint())
            return false;
    }
    return true;
}


UFUNCTION(BlueprintPure)
bool IsPlayerSwingin(AHazePlayerCharacter Player)
{
	return SwingComps[Player].HasActivateSwingPoint();
}

}
