// Check if location is within teardrop shape encapsulating two spheres
mixin bool IsInsideTeardrop(FVector Location, FVector Start, FVector End, float StartRadius, float EndRadius)
{
	float Fraction = 0.0;
	FVector CenterLineLoc;
	Math::ProjectPositionOnLineSegment(Start, End, Location, CenterLineLoc, Fraction);
	float Radius = Math::Lerp(StartRadius, EndRadius, Fraction);
	if (Location.IsWithinDist(CenterLineLoc, Radius))
		return true;
	return false;
}

// Check if location is within teardrop shape encapsulating two spheres
mixin bool IsInsideTeardrop2D(FVector Location, FVector Start, FVector End, float StartRadius, float EndRadius)
{
	FVector Start2D = FVector(Start.X, Start.Y, Location.Z); 
	FVector End2D = FVector(End.X, End.Y, Location.Z); 
	return Location.IsInsideTeardrop(Start2D, End2D, StartRadius, EndRadius);
}

namespace ShapeDebug
{
	void DrawTeardrop(FVector Start, FVector End, float StartRadius, float EndRadius, FLinearColor Color = FLinearColor::White, float Width = 3.0, float Duration = 0.0, FVector UpDir = FVector::UpVector)
	{
		if (Start.IsWithinDist(End, Math::Max3(SMALL_NUMBER, EndRadius - StartRadius, StartRadius - EndRadius)))
		{
			FVector Up = UpDir.GetSafeNormal();
			FVector YAxis = Up.CrossProduct((Up.X < 0.71) ? FVector::ForwardVector : (Up.Y < 0.71) ? FVector::RightVector : FVector::UpVector);
			FVector ZAxis = Up.CrossProduct(YAxis);
			Debug::DrawDebugCircle((StartRadius > EndRadius) ? Start : End, Math::Max(StartRadius, EndRadius), 12, Color, Width, YAxis, ZAxis, false, Duration);
			return;
		}

		FVector Smaller = Start, Larger = End;
		float SmallRadius = StartRadius, LargeRadius = EndRadius;
		if (EndRadius < StartRadius)
		{
			Smaller = End; Larger = Start;
			SmallRadius = EndRadius; LargeRadius = StartRadius;
		}

		float Dist = Smaller.Distance(Larger);
		FVector Dir = (Larger - Smaller).GetSafeNormal();
		FVector Right = Dir.CrossProduct(UpDir.GetSafeNormal());
		float Interval = 0.02;
		float RadiusDiff = LargeRadius - SmallRadius;
		float Angle = Math::Asin(RadiusDiff / Dist);

		// Base radius back end half circle
		FVector PrevRight = Smaller - Dir * SmallRadius;
		FVector PrevLeft = Smaller - Dir * SmallRadius;
		float Cos = 0.0, Sin = 0.0;
		for (float Rad = PI * (1.0 - Interval); Rad > PI * 0.5 + Angle - Interval * 0.1; Rad -= PI * Interval)
		{
			Math::SinCos(Sin, Cos, Rad);
			FVector NextRight = Smaller + (Right * Sin + Dir * Cos) * SmallRadius;
			Debug::DrawDebugLine(PrevRight, NextRight, Color, Width, Duration);
			PrevRight = NextRight;
			FVector NextLeft = Smaller + (-Right * Sin + Dir * Cos) * SmallRadius;
			Debug::DrawDebugLine(PrevLeft, NextLeft, Color, Width, Duration);
			PrevLeft = NextLeft; 
		}

		// Sidelines, then tip half circle
		for (float Rad = PI * 0.5 + Angle; Rad > -Interval * 0.1; Rad -= PI * Interval)
		{
			Math::SinCos(Sin, Cos, Rad);
			FVector NextRight = Larger + (Right * Sin + Dir * Cos) * LargeRadius;
			Debug::DrawDebugLine(PrevRight, NextRight, Color, Width, Duration);
			PrevRight = NextRight;
			FVector NextLeft = Larger + (-Right * Sin + Dir * Cos) * LargeRadius;
			Debug::DrawDebugLine(PrevLeft, NextLeft, Color, Width, Duration);
			PrevLeft = NextLeft;
		}
	}
}