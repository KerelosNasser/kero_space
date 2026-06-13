# Performance Audit

## 60fps Target Validation
- [x] Tested complex animations (Rive overlays, fancy tree view tasks) with Flutter DevTools.
- [x] Skia engine holds at 60fps during scrolling on main feature screens.

## Isar Query Optimization
- [x] Verified that critical collections have necessary `@Index()` annotations (e.g., `timestamp` on `ScreenEvent`, `date` on `Transaction`, `syncStatus` on `SyncOutboxRecord`).
- [x] Slow queries have been analyzed; paginated fetches are used for large lists like click logs to prevent memory exhaustion.
