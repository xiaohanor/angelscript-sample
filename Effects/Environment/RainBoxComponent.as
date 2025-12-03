
/**
 * 
 * The idea is to place this in a sheet. That way it will get removed when the 
 * associated level or system gets removed or streamed out
 * 
 * This will attach a shape to the player that contains rain particles.
 * 
 */

UCLASS(Abstract)
class URainBoxComponent : UActorComponent
{
	// we'll use a timer for this instead. More clear than settings tick intervals imo.
	default PrimaryComponentTick.bStartWithTickEnabled = false;
}