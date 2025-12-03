struct FPrisonStealthVisionCone
{
	float FullDepth;
	float CloseHalfWidth;
	float FarHalfWidth;
	float HalfHeight;
	float Radius;

	FPrisonStealthVisionCone(FVector Extent, float CloseWidthAlpha)
	{
		FullDepth = Extent.X * 2;
		CloseHalfWidth = Extent.Y * CloseWidthAlpha;
		FarHalfWidth = Extent.Y;
		HalfHeight = Extent.Z;
		Radius = FVector2D(FullDepth, FarHalfWidth).Size();
	}

	bool IsPointInside(FTransform VisionAreaTransform, FVector Point) const
	{
		FVector RelativePoint = VisionAreaTransform.InverseTransformPositionNoScale(Point);

		// Too far back
		if(RelativePoint.X < 0)
			return false;

		// Too far up/down
		if(Math::Abs(RelativePoint.Z) > HalfHeight)
			return false;

		// Get an alpha of how far through the vision cone we are
		// We allow this to go > 1, since we extend the cone a bit where the radius extends past the trapezoid
		float RelativePointDepthAlpha = Math::NormalizeToRange(RelativePoint.X, 0, FullDepth);
		float WidthAtRelativePoint = Math::Lerp(CloseHalfWidth, FarHalfWidth, RelativePointDepthAlpha);

		// Too far out left/right
		if(Math::Abs(RelativePoint.Y) > WidthAtRelativePoint)
			return false;

		// Too far out
		if(RelativePoint.Size() > Radius)
			return false;

		return true;
	}

	private TArray<FVector> GetVertices(FTransform VisionAreaTransform) const
	{
		// Low vertices
		FVector BLL = VisionAreaTransform.TransformPositionNoScale(FVector(0, -CloseHalfWidth, -HalfHeight));
		FVector FLL = VisionAreaTransform.TransformPositionNoScale(FVector(FullDepth, -FarHalfWidth, -HalfHeight));
		FVector BRL = VisionAreaTransform.TransformPositionNoScale(FVector(0, CloseHalfWidth, -HalfHeight));
		FVector FRL = VisionAreaTransform.TransformPositionNoScale(FVector(FullDepth, FarHalfWidth, -HalfHeight));

		// Middle vertices
		FVector BLM = VisionAreaTransform.TransformPositionNoScale(FVector(0, -CloseHalfWidth, 0));
		FVector FLM = VisionAreaTransform.TransformPositionNoScale(FVector(FullDepth, -FarHalfWidth, 0));
		FVector BRM = VisionAreaTransform.TransformPositionNoScale(FVector(0, CloseHalfWidth, 0));
		FVector FRM = VisionAreaTransform.TransformPositionNoScale(FVector(FullDepth, FarHalfWidth, 0));

		// High vertices
		FVector BLH = VisionAreaTransform.TransformPositionNoScale(FVector(0, -CloseHalfWidth, HalfHeight));
		FVector FLH = VisionAreaTransform.TransformPositionNoScale(FVector(FullDepth, -FarHalfWidth, HalfHeight));
		FVector BRH = VisionAreaTransform.TransformPositionNoScale(FVector(0, CloseHalfWidth, HalfHeight));
		FVector FRH = VisionAreaTransform.TransformPositionNoScale(FVector(FullDepth, FarHalfWidth, HalfHeight));

		TArray<FVector> Vertices;
		Vertices.Reserve(12);

		Vertices.Add(BLL);
		Vertices.Add(FLL);
		Vertices.Add(BRL);
		Vertices.Add(FRL);

		Vertices.Add(BLM);
		Vertices.Add(FLM);
		Vertices.Add(BRM);
		Vertices.Add(FRM);

		Vertices.Add(BLH);
		Vertices.Add(FLH);
		Vertices.Add(BRH);
		Vertices.Add(FRH);

		return Vertices;
	}

	void VisualizeVisionCone(const UHazeScriptComponentVisualizer Visualizer, FTransform VisionAreaTransform, FLinearColor Color, float Thickness = 3.0, bool bScreenSpace = false) const
	{
		const TArray<FVector> Vertices = GetVertices(VisionAreaTransform);

		Visualizer.DrawLine(Vertices[0], Vertices[1], Color, Thickness, bScreenSpace);	// BL to FL
		//Visualizer.DrawLine(Vertices[1], Vertices[3], Color, Thickness, bScreenSpace);// FL to FR
		Visualizer.DrawLine(Vertices[3], Vertices[2], Color, Thickness, bScreenSpace);	// FR to BR
		Visualizer.DrawLine(Vertices[2], Vertices[0], Color, Thickness, bScreenSpace);	// BR to BL

		Visualizer.DrawLine(Vertices[4], Vertices[5], Color, Thickness, bScreenSpace);
		//Visualizer.DrawLine(Vertices[5], Vertices[7], Color, Thickness, bScreenSpace);
		Visualizer.DrawLine(Vertices[7], Vertices[6], Color, Thickness, bScreenSpace);
		Visualizer.DrawLine(Vertices[6], Vertices[4], Color, Thickness, bScreenSpace);

		Visualizer.DrawLine(Vertices[8], Vertices[9], Color, Thickness, bScreenSpace);
		//Visualizer.DrawLine(Vertices[9], Vertices[11], Color, Thickness, bScreenSpace);
		Visualizer.DrawLine(Vertices[11], Vertices[10], Color, Thickness, bScreenSpace);
		Visualizer.DrawLine(Vertices[10], Vertices[8], Color, Thickness, bScreenSpace);

		Visualizer.DrawLine(Vertices[0], Vertices[8], Color, Thickness, bScreenSpace);	// BLL to BLH
		Visualizer.DrawLine(Vertices[1], Vertices[9], Color, Thickness, bScreenSpace);	// FLL to FLH
		Visualizer.DrawLine(Vertices[2], Vertices[10], Color, Thickness, bScreenSpace);	// FLL to FLH
		Visualizer.DrawLine(Vertices[3], Vertices[11], Color, Thickness, bScreenSpace);	// FLL to FLH

		const FVector HeightOffset = FVector(0, 0, HalfHeight);
		const float Angle = Math::DirectionToAngleDegrees(FVector2D(FullDepth, FarHalfWidth)) * 2;
		Visualizer.DrawArc(VisionAreaTransform.Location + HeightOffset, Angle, Radius, VisionAreaTransform.Rotation.ForwardVector, Color, Thickness, FVector::UpVector, 16, 0, false);
		Visualizer.DrawArc(VisionAreaTransform.Location, Angle, Radius, VisionAreaTransform.Rotation.ForwardVector, Color, Thickness, FVector::UpVector, 16, 0, false);
		Visualizer.DrawArc(VisionAreaTransform.Location - HeightOffset, Angle, Radius, VisionAreaTransform.Rotation.ForwardVector, Color, Thickness, FVector::UpVector, 16, 0, false);
		
		FVector FarVertexTop = VisionAreaTransform.TransformPositionNoScale(FVector(Radius, 0, HalfHeight));
		FVector FarVertexBot = VisionAreaTransform.TransformPositionNoScale(FVector(Radius, 0, -HalfHeight));
		Visualizer.DrawLine(FarVertexTop, FarVertexBot, Color, Thickness, bScreenSpace);
	}

	void DebugDrawVisionCone(FTransform VisionAreaTransform, FLinearColor Color, float Thickness = 3.0)
	{
		const TArray<FVector> Vertices = GetVertices(VisionAreaTransform);

		Debug::DrawDebugLine(Vertices[0], Vertices[1], Color, Thickness);
		Debug::DrawDebugLine(Vertices[1], Vertices[3], Color, Thickness);
		Debug::DrawDebugLine(Vertices[3], Vertices[2], Color, Thickness);
		Debug::DrawDebugLine(Vertices[2], Vertices[0], Color, Thickness);

		Debug::DrawDebugLine(Vertices[4], Vertices[5], Color, Thickness);
		Debug::DrawDebugLine(Vertices[5], Vertices[7], Color, Thickness);
		Debug::DrawDebugLine(Vertices[7], Vertices[6], Color, Thickness);
		Debug::DrawDebugLine(Vertices[6], Vertices[4], Color, Thickness);

		Debug::DrawDebugLine(Vertices[0], Vertices[4], Color, Thickness);
		Debug::DrawDebugLine(Vertices[1], Vertices[5], Color, Thickness);
		Debug::DrawDebugLine(Vertices[2], Vertices[6], Color, Thickness);
		Debug::DrawDebugLine(Vertices[3], Vertices[7], Color, Thickness);

		const FVector HeightOffset = FVector(0, 0, HalfHeight);
		Debug::DrawDebugCircle(VisionAreaTransform.Location + HeightOffset, Radius, 16, Color, 3, FVector::RightVector, FVector::UpVector);
		Debug::DrawDebugCircle(VisionAreaTransform.Location - HeightOffset, Radius, 16, Color, 3, FVector::RightVector, FVector::UpVector);
	}
};