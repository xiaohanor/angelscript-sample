class USkylineRappellerRopeCollisionComponent : UCapsuleComponent
{
	default CollisionProfileName = n"OverlapAll";
	default RelativeLocation = FVector(0.0, 0.0, 200.0);
	default CapsuleRadius = 50.0;
	default CapsuleHalfHeight = 100.0;

	bool bIsCut = false;
}

