/***
 * Sphere that has the capability of applying 
 * one-shot forces to chaos destruction pieces 
 * that it overlaps.
 */

UCLASS()
class AExampleImpactFieldSystemActor : ABaseImpactFieldSystemActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	// controls the size of the sphere
	default SphereCollision.SphereRadius = 150.0;

	/* 	How much breaking force is applied per one-shot. 
		The affected Chaos destruction mesh has a 'Strain' 
		threshold specified which this force needs to 
		exceed for it to break into pieces.  */
	default StrainMagnitude = 1000000.0;

	/**
	 * How much linear force that will be applied 
	 * to overlapping pieces when the overlap this sphere
	 */
	default ForceMagnitude = 6000000.0;

	/**
	 * How much rotational force to be applied to overlapping pieces
	 */
	default TorqueMagnitude = 300000.0;

	/**
	 * Emits one-shot forces and torques to pieces that overlap this sphere. 
	 * The linear forces are omnidirection but can be constrained to a direction
	 * if the OptionalDirection is set to something other than 0 Vector.
	 */
	void ApplyFieldForceAtLocation( FVector InLocation, FVector OptionalDirection = FVector(0)) override
	{
		//Debug::DrawDebugSphere(InLocation, SphereCollision.GetScaledSphereRadius());

		// Calls the base class implementation that applies the forces and moves this sphere)
		Super::ApplyFieldForceAtLocation(InLocation, OptionalDirection);
	}
}