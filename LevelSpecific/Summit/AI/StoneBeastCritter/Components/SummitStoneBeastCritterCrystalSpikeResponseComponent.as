event void FSummitStoneBeastCritterCrystalSpikeResponseSignature(AHazeActor Instigator);

class USummitStoneBeastCritterCrystalSpikeResponseComponent : UActorComponent
{
	FSummitStoneBeastCritterCrystalSpikeResponseSignature OnHit;

	void Die(AHazeActor Instigator)
	{
		OnHit.Broadcast(Instigator);
	}
};