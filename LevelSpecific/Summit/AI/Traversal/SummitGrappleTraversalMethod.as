class USummitGrappleTraversalMethod : USummitLeapTraversalMethod
{
	// Currently we generate a ballistic trajectory, same as with a leap. 
	// If we need larger differences we should consider removing inheritance.

	default ScenepointClass = UTrajectoryTraversalScenepoint;
	default VisualizationColor = FLinearColor(1.0, 0.5, 0.0);

	default MaxLeapSpeed = 3000.0;
	default IdealAngle = 15.0;
}
